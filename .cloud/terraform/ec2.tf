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
    sudo yum update -y
    sudo yum install -y suricata iptables-services

    # Activer l’IP forwarding
    sudo echo 1 > /proc/sys/net/ipv4/ip_forward
    sudo sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

    # Rediriger HTTP (port 80) vers la VM Web (10.0.0.96:80 par ex.)
    sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.0.96:80
    sudo iptables -A FORWARD -p tcp -d 10.0.0.96 --dport 80 -j ACCEPT
    sudo service iptables save

    # Installer et démarrer Suricata
    systemctl enable suricata
    systemctl start suricata
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