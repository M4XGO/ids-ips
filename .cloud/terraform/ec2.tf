resource "aws_instance" "suricata_vm" {
  ami           = "ami-08da5407960580f18" # Remplacez par l'AMI de votre choix (Ubuntu/Debian)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = "deployer-key"
  private_ip    = "10.0.1.10"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name


  tags = {
    Name = "Suricata-VM"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Mise à jour des paquets
              apt update -y
              apt install -y suricata iptables iptables-persistent

              sudo apt install -y amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent

              # Activer le forwarding réseau
              echo 1 > /proc/sys/net/ipv4/ip_forward
              sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
              sysctl -p

              # Configurer Suricata pour capturer le trafic réseau (mode Sniffer)
              cat <<EOT > /etc/suricata/suricata.yaml
              af-packet:
                - interface: eth0
                  cluster-id: 99
                  cluster-type: cluster_flow
                  defrag: yes
                  bypass: yes
              EOT

              # Rediriger le trafic HTTP (port 80) vers la VM Web (10.0.1.2)
              iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.1.2:80
              iptables -A FORWARD -p tcp -d 10.0.1.2 --dport 80 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

              # Sauvegarder la configuration iptables
              iptables-save > /etc/iptables/rules.v4

              # Démarrer Suricata
              systemctl enable suricata
              systemctl start suricata
            EOF
}

resource "aws_instance" "web_vm" {
  ami           = "ami-08da5407960580f18" # Replace with a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = "deployer-key"
  private_ip    = "10.0.1.21"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name


  tags = {
    Name = "Web-VM"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y docker.io
              sudo apt install -y amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent
              docker run -d -p 80:80 nginx
            EOF
}

resource "aws_instance" "attack_vm" {
  ami           = "ami-08da5407960580f18"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = "deployer-key"
  private_ip    = "10.0.1.20"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name


  tags = {
    Name = "Attack-VM"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y docker.io
              sudo apt install -y amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent
              docker pull kalilinux/kali-rolling
              docker run -it kalilinux/kali-rolling /bin/bash
              apt update && apt -y install kali-linux-headless
            EOF
}

resource "aws_instance" "bastion" {
  ami           = "ami-08da5407960580f18" # Utilisez le même AMI que vos autres VMs
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = "deployer-key"
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name

  tags = {
    Name = "Bastion-Host"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent
            EOF
}
