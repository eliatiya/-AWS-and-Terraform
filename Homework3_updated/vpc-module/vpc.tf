# VPC
resource "aws_vpc" "vpc" {
  cidr_block  = var.vpc_cidr_block

  tags = {
    "Name" = "Whiskey_VPC"
  }
}

# Public Subnets, one in each AZ
resource "aws_subnet" "public" {
  map_public_ip_on_launch = "true"
  count                   = length(var.public_subnet_list)
  cidr_block              = var.public_subnet_list[count.index]
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.aws_availability_zones[count.index]

  tags = {
    "Name" = "Public_subnet_${regex(".$", var.aws_availability_zones[count.index])}_${aws_vpc.vpc.id}"
  }
}

# Private Subnets, one in each AZ
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_list)
  cidr_block              = var.private_subnet_list[count.index]
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "false"
  availability_zone       = var.aws_availability_zones[count.index]

  tags = {
    "Name" = "Private_subnet_${regex(".$", var.aws_availability_zones[count.index])}_${aws_vpc.vpc.id}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "IGW_${aws_vpc.vpc.id}"
  }
}

# EIPs (for nats, 1 in each Public subnet)
resource "aws_eip" "eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  count = length(var.public_subnet_list)

  tags = {
    "Name" = "NAT_elastic_ip_${regex(".$", var.aws_availability_zones[count.index])}_${aws_vpc.vpc.id}"
  }
}

# NAT, 1 in each Public subnet
resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnet_list)
  allocation_id = aws_eip.eip.*.id[count.index]
  subnet_id     = aws_subnet.public.*.id[count.index]
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    "Name" = "NAT_${regex(".$", var.aws_availability_zones[count.index])}_${aws_vpc.vpc.id}"
  }
}

# ROUTING #
resource "aws_route_table" "route_tables" {
  count  = length(var.route_tables_names_list)
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.route_tables_names_list[count.index]}_RTB_${aws_vpc.vpc.id}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_list)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.route_tables[0].id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_list)
  subnet_id      = aws_subnet.private.*.id[count.index]
  route_table_id = aws_route_table.route_tables[count.index + 1].id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.route_tables[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private" {
  count                  = length(var.private_subnet_list)
  route_table_id         = aws_route_table.route_tables.*.id[count.index + 1]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.*.id[count.index]
}