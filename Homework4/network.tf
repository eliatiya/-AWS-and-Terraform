module "vpc" {
  source  = "app.terraform.io/example-org-a7ff27/vpc/cloud"
  version = "1.0.0"
  # insert required variables here
  vpc_cidr_block          = "192.168.0.0/16"
  private_subnet_list     = ["192.168.10.0/24", "192.168.20.0/24"]
  public_subnet_list      = ["192.168.100.0/24", "192.168.200.0/24"]
  aws_availability_zones  = slice(data.aws_availability_zones.available.*.names[0], 0, 2)
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
  cidr_blocks = [module.vpc.vpc_cider]

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