# Other network interface to use with the bastion to allow access to the internet
resource "aws_network_interface" "suricata_vm_eni" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.1.11"]

  tags = {
    Name = "Suricata-VM-ENI"
  }
}

resource "aws_instance" "suricata_vm" {
  ami                  = "ami-08da5407960580f18"
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.private_subnet.id
  key_name             = "deployer-key"
  private_ip           = "10.0.1.10"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  network_interface {
    network_interface_id = aws_network_interface.suricata_vm_eni.id
    device_index         = 1
  }


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

# Other network interface to use with the bastion to allow access to the internet
resource "aws_network_interface" "web_vm_eni" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.1.31"]

  tags = {
    Name = "WEB-VM-ENI"
  }
}

resource "aws_instance" "web_vm" {
  ami                  = "ami-08da5407960580f18" # Replace with a valid AMI ID
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.private_subnet.id
  key_name             = "deployer-key"
  private_ip           = "10.0.1.30"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  network_interface {
    network_interface_id = aws_network_interface.web_vm_eni.id
    device_index         = 1
  }

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

# Other network interface to use with the bastion to allow access to the internet
resource "aws_network_interface" "attack_vm_eni" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.1.21"]

  tags = {
    Name = "Attack-VM-ENI"
  }
}

resource "aws_instance" "attack_vm" {
  ami                  = "ami-08da5407960580f18"
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.private_subnet.id
  key_name             = "deployer-key"
  private_ip           = "10.0.1.20"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  network_interface {
    network_interface_id = aws_network_interface.attack_vm_eni.id
    device_index         = 1
  }


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
