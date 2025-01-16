resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main_vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main_igw" }
}

resource "aws_subnet" "main_subnet" {
  vpc_id                 = aws_vpc.main.id
  cidr_block             = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone      = "eu-west-3a"
  tags = { Name = "main_subnet" }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "main_rt" }
}

resource "aws_route_table_association" "main_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}