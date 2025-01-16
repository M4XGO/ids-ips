resource "aws_security_group" "suricata_sg" {
  name        = "suricata_sg"
  description = "Allow all inbound & outbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "suricata_sg" }
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow traffic from Suricata"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from Suricata"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.suricata_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "web_sg" }
}
