resource "aws_security_group" "vm_sg" {
  name        = "vm_sg"
  description = "Allow SSH from bastion and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  // Autoriser SSH UNIQUEMENT depuis le groupe de sécurité du bastion
  ingress {
    description              = "Allow SSH from bastion SG"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    # On référence le groupe de sécurité du bastion
    security_groups          = [aws_security_group.bastion_sg.id]
  }

  // Autoriser le ping (ICMP) depuis n'importe où (facultatif)
  ingress {
    description = "Allow ICMP for ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Autoriser tout le trafic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vm_sg"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id

  // Autoriser SSH depuis partout vers le bastion (ou restreindre selon vos besoins)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Autoriser le trafic sortant illimité
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion_sg"
  }
}