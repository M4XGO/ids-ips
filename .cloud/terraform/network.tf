resource "aws_vpc" "private_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Private-VPC"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.private_vpc.id
  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = false
  tags = {
    Name = "Private-Subnet"
  }
}
