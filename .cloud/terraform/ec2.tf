resource "aws_instance" "suricata_vm" {
  ami                    = "ami-0b7174cd777d2d9ff"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.suricata_sg.id]
  key_name               = "deployer-key"
  source_dest_check      = false  # important pour faire du forwarding

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
    sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to 10.0.0.98:80
    sudo iptables -A FORWARD -p tcp -d 10.0.0.98 --dport 80 -j ACCEPT
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    
    # Sauvegarder iptables
    sudo service iptables save
    
    # Configuration Nginx
    sudo tee /etc/nginx/conf.d/reverse-proxy.conf <<'EOF'
    server {
        listen 80;
        server_name _;
        
        location / {
            proxy_pass http://10.0.0.98:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
EOF

    # Redémarrer les services
    sudo systemctl enable nginx
    sudo systemctl restart nginx

    sudo amazon-linux-extras enable epel
    sudo yum clean metadata
    sudo yum install -y epel-release
    sudo yum install -y suricata
    sudo systemctl enable suricata
    sudo systemctl restart suricata
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