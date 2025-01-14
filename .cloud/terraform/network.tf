resource "aws_vpc" "private_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Private-VPC"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.private_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-3a"

  # map_public_ip_on_launch = false
  tags = {
    Name = "Private-Subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.private_vpc.id

  tags = {
    Name = "main_igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.private_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Allow SSH access to bastion host"
  vpc_id      = aws_vpc.private_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface_sg_attachment" "bastion_sg_attachment" {
  security_group_id    = aws_security_group.bastion_sg.id
  network_interface_id = aws_instance.bastion.primary_network_interface_id
}

# # Endpoint pour SSM
# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id       = aws_vpc.private_vpc.id # Remplacez par l'ID de votre VPC
#   service_name = "com.amazonaws.${data.aws_region.current.name}.ssm"

#   vpc_endpoint_type = "Interface"
#   # security_group_ids = [
#   #   aws_security_group.ssm_endpoint_sg.id
#   # ]
#   subnet_ids = [
#     aws_subnet.private_subnet.id # Remplacez par les sous-réseaux où résident vos instances EC2
#   ]
# }

# # Endpoint pour Systems Manager Messages
# resource "aws_vpc_endpoint" "ssmmessages" {
#   vpc_id       = aws_vpc.private_vpc.id
#   service_name = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"

#   vpc_endpoint_type = "Interface"
#   # security_group_ids = [
#   #   aws_security_group.ssm_endpoint_sg.id
#   # ]
#   subnet_ids = [
#     aws_subnet.private_subnet.id
#   ]
# }

# # Endpoint pour EC2 Messages
# resource "aws_vpc_endpoint" "ec2messages" {
#   vpc_id       = aws_vpc.private_vpc.id
#   service_name = "com.amazonaws.${data.aws_region.current.name}.ec2messages"

#   vpc_endpoint_type = "Interface"
#   # security_group_ids = [
#   #   aws_security_group.ssm_endpoint_sg.id
#   # ]
#   subnet_ids = [
#     aws_subnet.private_subnet.id
#   ]
# }

# # # Security group pour les VPC Endpoints
# # resource "aws_security_group" "ssm_endpoint_sg" {
# #   name        = "ssm-endpoint-sg"
# #   vpc_id      = aws_vpc.private_vpc.id
# #   description = "Security group for SSM VPC Endpoints"

# #   ingress {
# #     from_port   = -1
# #     to_port     = -1
# #     protocol    = "tcp"
# #     cidr_blocks = ["0.0.0.0/0"]
# #   }

# #   egress {
# #     from_port   = -1
# #     to_port     = -1
# #     protocol    = "-1"
# #     cidr_blocks = ["0.0.0.0/0"]
# #   }
# # }