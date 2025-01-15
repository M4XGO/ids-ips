############ SURICATA VM ############

resource "aws_network_interface" "suricata_vm_eni_private" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.1.10"]
  security_groups = [aws_security_group.vm_sg.id]

  tags = {
    Name = "Suricata-VM-ENI-Private"
  }
}

resource "aws_network_interface" "suricata_vm_eni_public" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["10.0.0.10"]
  security_groups = [aws_security_group.vm_sg.id]

  tags = {
    Name = "Suricata-VM-ENI-Public"
  }
}

resource "aws_instance" "suricata_vm" {
  ami                  = "ami-09be70e689bddcef5"
  instance_type        = "t2.micro"
  key_name             = "deployer-key"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  network_interface {
    network_interface_id = aws_network_interface.suricata_vm_eni_private.id
    device_index         = 1
  }
  network_interface {
    network_interface_id = aws_network_interface.suricata_vm_eni_public.id
    device_index         = 0
  }

  tags = {
    Name = "Suricata-VM"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y suricata iptables iptables-persistent

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

              # Rediriger le trafic HTTP (port 80) vers la VM Web (10.0.1.30)
              iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.1.30:80
              iptables -A FORWARD -p tcp -d 10.0.1.30 --dport 80 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

              # Sauvegarder la configuration iptables
              iptables-save > /etc/iptables/rules.v4

              # Démarrer Suricata
              systemctl enable suricata
              systemctl start suricata
            EOF
}


############ Web VM ############
resource "aws_network_interface" "web_vm_eni_private" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.1.30"]
  security_groups = [aws_security_group.vm_sg.id]

  tags = {
    Name = "WEB-VM-ENI-Private"
  }
}

resource "aws_network_interface" "web_vm_eni_public" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["10.0.0.30"]
  security_groups = [aws_security_group.vm_sg.id]

  tags = {
    Name = "WEB-VM-ENI-Public"
  }
}

resource "aws_instance" "web_vm" {
  ami                  = "ami-09be70e689bddcef5"
  instance_type        = "t2.micro"
  key_name             = "deployer-key"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  network_interface {
    network_interface_id = aws_network_interface.web_vm_eni_private.id
    device_index         = 1
  }
  network_interface {
    network_interface_id = aws_network_interface.web_vm_eni_public.id
    device_index         = 0
  }

  tags = {
    Name = "Web-VM"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y docker.io
              docker run -d -p 80:80 nginx
            EOF
}


############ ATTACK VM ############
resource "aws_network_interface" "attack_vm_eni_private" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.1.20"]
  security_groups = [aws_security_group.vm_sg.id]

  tags = {
    Name = "Attack-VM-ENI-Private"
  }
}

resource "aws_network_interface" "attack_vm_eni_public" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["10.0.0.20"]
  security_groups = [aws_security_group.vm_sg.id]

  tags = {
    Name = "Attack-VM-ENI-Public"
  }
}

resource "aws_instance" "attack_vm" {
  ami                  = "ami-09be70e689bddcef5"
  instance_type        = "t2.micro"
  key_name             = "deployer-key"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  network_interface {
    network_interface_id = aws_network_interface.attack_vm_eni_private.id
    device_index         = 1
  }
  network_interface {
    network_interface_id = aws_network_interface.attack_vm_eni_public.id
    device_index         = 0
  }

  tags = {
    Name = "Attack-VM"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y docker.io
              docker pull kalilinux/kali-rolling
              docker run -it kalilinux/kali-rolling /bin/bash
              apt update && apt -y install kali-linux-headless
            EOF
}

############ BASTION HOST ############

resource "aws_instance" "bastion" {
  ami                         = "ami-08da5407960580f18"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  key_name                    = "deployer-key"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y openssh-server

              # Configuration SSH
              sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              systemctl restart ssh
            EOF

  tags = {
    Name = "Bastion-Host"
  }
}