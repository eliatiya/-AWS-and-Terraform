# NETWORKING #
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  cidr              = var.vpc_cidr_block
  enable_nat_gateway      = true
  enable_dns_hostnames    = var.enable_dns_hostnames

  tags = {
    Name        = "vpc"
    Environment = "aws_vpc"
  }

}

/*==== Subnets ======*/
/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name        = "igw"
  }
}
/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}
/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on    = [aws_internet_gateway.ig]
  tags = {
    Name        = "nat"
  }
}
/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = module.vpc.vpc_id
  count                   = "${length(var.public_subnets_cidr)}"
  cidr_block              = "${element(var.public_subnets_cidr,   count.index)}"
  availability_zone       = "${element(var.availability_zones,   count.index)}"
  map_public_ip_on_launch = true
  tags = {
    Name        = "aws-${element(var.availability_zones, count.index)}-public-subnet"
  }
}
/* Private subnet */
resource "aws_subnet" "private_subnet" {
  vpc_id                  = module.vpc.vpc_id
  count                   = "${length(var.private_subnets_cidr)}"
  cidr_block              = "${element(var.private_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.private_availability_zones,   count.index)}"
  map_public_ip_on_launch = false
  tags = {
    Name        = "aws-${element(var.private_availability_zones, count.index)}-private-subnet"
  }
}
/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name        = "aws-private-route-table"
  }
}
/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name        = "aws-public-route-table"
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig.id}"
}
resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}
/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}
resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}
/*==== VPC's public Security Group ======*/
resource "aws_security_group" "public" {
  name        = "aws-public-sg"
  description = "public security group to allow inbound/outbound from the VPC"
  vpc_id      = module.vpc.vpc_id
  depends_on  = [module.vpc]
  tags = {
    Environment = "aws-public-sec-group"
  }
}

resource "aws_security_group_rule" "public_ingress_1" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.public.id}"
}
resource "aws_security_group_rule" "public_ingress_2" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.public.id}"
}
resource "aws_security_group_rule" "public_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.public.id}"
}
/*==== VPC's private Security Group ======*/
resource "aws_security_group" "private" {
  name        = "aws-private-sg"
  description = "private security group to allow inbound/outbound from the VPC"
  vpc_id      = module.vpc.vpc_id
  depends_on  = [module.vpc]
  tags = {
    Environment = "aws-private-sec-group"
  }
}
resource "aws_security_group_rule" "private_ingress" {
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [var.vpc_cidr_block]

  security_group_id = "${aws_security_group.private.id}"
}
resource "aws_security_group_rule" "private_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.private.id}"
}