resource "aws_instance" "suricata_vm" {
  ami                    = "ami-0b7174cd777d2d9ff"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.suricata_sg.id]
  key_name               = "deployer-key"
  source_dest_check      = false  # important pour faire du forwarding
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOT
    #!/bin/bash
    # Installation des packages
    sudo yum update -y
    sudo yum install -y suricata iptables-services
    sudo amazon-linux-extras install nginx1 -y

    # Configuration IP forwarding
    sudo echo 1 > /proc/sys/net/ipv4/ip_forward
    sudo sysctl -p

    # Configuration iptables
    sudo iptables -F
    sudo iptables -t nat -F
    
    # Accepter le trafic HTTP entrant
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT
    
    # Configurer le NAT
    sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to ${aws_instance.web_vm.private_ip}:80
    sudo iptables -A FORWARD -p tcp -d ${aws_instance.web_vm.private_ip} --dport 80 -j ACCEPT
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    
    # Sauvegarder iptables
    sudo service iptables save
    
    # Configuration Nginx
    cat > /etc/nginx/conf.d/reverse-proxy.conf << 'NGINXEOF'
    server {
        listen 80;
        server_name _;
        
        location / {
            proxy_pass http://${aws_instance.web_vm.private_ip}:80;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
NGINXEOF

    # Redémarrer les services
    sudo systemctl enable nginx
    sudo systemctl restart nginx

    sudo amazon-linux-extras enable epel
    sudo yum clean metadata
    sudo yum install -y epel-release
    sudo yum install -y suricata
    sudo systemctl enable suricata
    sudo systemctl restart suricata

    sudo systemctl restart suricata
    sudo sed -i 's/community-id: false/community-id: true/' /etc/suricata/suricata.yaml
    sudo service suricata restart
    sudo suricata-update
    sudo suricata-update --no-check-certificate update-sources
    sudo suricata-update list-sources
    sudo suricata-update enable-source et/open
    sudo suricata-update
    sudo suricata -T -c /etc/suricata/suricata.yaml -v
    sudo suricata-update -o /etc/suricata/rules
    sudo suricata -T -c /etc/suricata/suricata.yaml -v

    sudo touch /var/lib/suricata/rules/local.rules
    sudo bash -c 'cat > /var/lib/suricata/rules/local.rules << "RULESEOF"
alert tcp any any -> any 80 (msg:"DDoS SYN flood detected"; flow:to_server; flags:S; threshold:type both,track by_src,count 50,seconds 5; sid:1000005; rev:2;)
alert tcp any any -> any 80 (msg:"Potential HTTP DDoS detected"; flow:to_server; flags:S; threshold:type both,track by_src,count 100,seconds 10; sid:1000006; rev:1;)
RULESEOF'

    sudo sed -i '/- suricata.rules/a\ - local.rules' /etc/suricata/suricata.yaml
    
    sudo chown -R suricata:suricata /etc/suricata/rules
    sudo suricata-update -o /etc/suricata/rules
    sudo suricata-update list-sources
    sudo suricata-update enable-source et/open
    sudo suricata -T -c /etc/suricata/suricata.yaml -v
    sudo suricata-update --no-check-certificate update-sources
    sudo systemctl restart suricata

    # Installation CloudWatch Agent
    sudo yum install -y amazon-cloudwatch-agent

    # # Création du répertoire .aws
    # sudo mkdir -p /root/.aws/

    # Configuration CloudWatch Agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWEOF'
    {
      "agent": {
        "region": "eu-west-3"
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/suricata/fast.log",
                "log_group_name": "/suricata/logs",
                "log_stream_name": "suricata-log-stream"
              }
            ]
          }
        }
      }
    }
CWEOF

    # Démarrage CloudWatch Agent
    sudo systemctl enable amazon-cloudwatch-agent
    sudo systemctl start amazon-cloudwatch-agent
  EOT

  tags = { Name = "Suricata-VM" }
}

resource "aws_instance" "web_vm" {
  ami                    = "ami-031e4310b9132e755" #ubuntu with apache pre-installed
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main_subnet.id
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "deployer-key"

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Bienvenue sur la VM Web</h1>" > /var/www/html/index.html
  EOF

  tags = { Name = "Web-VM" }
}