
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "main" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "main-route-table"
  }
}

resource "aws_route_table_association" "a" {
  count          = length(aws_subnet.main)
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main.id
}

module "ec2" {
  source = "./modules/ec2"

  vpc_id    = aws_vpc.main.id
  subnet_id = aws_subnet.main[0].id
}