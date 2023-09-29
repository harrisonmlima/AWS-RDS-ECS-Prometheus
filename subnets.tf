resource "aws_subnet" "main-subnet-public-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.100.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "main-subnet-public-1a"
  }
}


resource "aws_subnet" "main-subnet-private-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "main-subnet-private-1a"
  }
}



resource "aws_subnet" "main-subnet-public-1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "main-subnet-public-1b"
  }
}


resource "aws_subnet" "main-subnet-private-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "main-subnet-private-1b"
  }
}