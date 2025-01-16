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
    yum update -y

    # Installation de Suricata et CloudWatch Agent
    amazon-linux-extras enable epel
    yum install -y suricata jq htop amazon-cloudwatch-agent

    # Configuration de Suricata
    echo "RUN=yes" > /etc/default/suricata
    suricata -i eth0 --init-errors-fatal

    # Configuration du CloudWatch Agent pour relayer eve.json
    cat << EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/suricata/eve.json",
                "log_group_name": "suricata-logs",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        },
        "log_stream_name": "suricata-eve-logs",
        "region": "eu-west-3"
      }
    }
    EOF

    systemctl enable amazon-cloudwatch-agent
    systemctl start amazon-cloudwatch-agent

    # Démarrage de Suricata
    systemctl enable suricata
    systemctl start suricata
  EOT

  tags = { Name = "Suricata-VM" }
}

resource "aws_instance" "web_vm" {
  ami                    = "ami-0b7174cd777d2d9ff"
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