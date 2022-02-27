terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.1.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
	region     = "us-west-2"
	access_key = ""
	secret_key = ""
}
resource "aws_instance" "web_app" {
	count         = 2
	ami           = "ami-0892d3c7ee96c0bf7"
	instance_type = "t3.micro"
	key_name = "develop"
	vpc_security_group_ids = [aws_security_group.public.id]
        subnet_id = "${element(aws_subnet.public_subnet.*.id, count.index)}"
	user_data = trimspace(<<EOF
		#! /bin/bash
        apt-get update
		apt-get install -y nginx
		systemctl start nginx
		systemctl enable nginx
		echo "<h1>'Welcome to Grandpa's Whiskey'</h1>" | sudo tee /var/www/html/index.nginx-debian.html
	EOF
	)

    root_block_device {
		volume_size           = "10"
		volume_type           = "gp2"
		encrypted             = false
		delete_on_termination = true
	}
    ebs_block_device {
		device_name = "/dev/sdb"
		volume_size           = "10"
		volume_type           = "gp2"
		encrypted             = true
		delete_on_termination = true
	}

	tags = {
			owner = "eliezer"
			name = "nginx server"
			purpose = "Whiskey"
		}
}
resource "aws_instance" "db_app" {
	count         = 2
	ami           = "ami-0892d3c7ee96c0bf7"
	instance_type = "t3.micro"
	key_name = "develop"
	vpc_security_group_ids = [aws_security_group.private.id]
        subnet_id = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  	user_data = trimspace(<<EOF
		#! /bin/bash
        apt-get update
		apt-get install -y nginx
		systemctl start nginx
		systemctl enable nginx
		echo "<h1>'DBS APP'</h1>" | sudo tee /var/www/html/index.nginx-debian.html
	EOF
	)

    root_block_device {
		volume_size           = "10"
		volume_type           = "gp2"
		encrypted             = false
		delete_on_termination = true
	}
    ebs_block_device {
		device_name = "/dev/sdb"
		volume_size           = "10"
		volume_type           = "gp2"
		encrypted             = true
		delete_on_termination = true
	}

	tags = {
			owner = "eliezer"
			name = "DBs"
			purpose = "store Whiskey"
		}
}
/*==== The VPC ======*/
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "vpc"
    Environment = "aws_vpc"
  }
}
/*==== Subnets ======*/
/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
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
  vpc_id                  = "${aws_vpc.vpc.id}"
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
  vpc_id                  = "${aws_vpc.vpc.id}"
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
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name        = "aws-private-route-table"
  }
}
/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
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
  vpc_id      = "${aws_vpc.vpc.id}"
  depends_on  = [aws_vpc.vpc]
    ingress {
	from_port   = 80
	to_port     = 80
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
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
  tags = {
    Environment = "aws-public-sec-group"
  }
}

/*==== VPC's private Security Group ======*/
resource "aws_security_group" "private" {
  name        = "aws-private-sg"
  description = "private security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.vpc.id}"
  depends_on  = [aws_vpc.vpc]
  ingress {
	from_port   = 0
	to_port     = 0
	protocol    = "-1"
	cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
	from_port   = 0
	to_port     = 0
	protocol    = "-1"
	cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "aws-private-sec-group"
  }
}

/*==== Create a new load balancer======*/  
resource "aws_elb" "terra-elb" {
  name               = "terra-elb"
  subnets = [aws_subnet.public_subnet[0].id,aws_subnet.public_subnet[1].id]
  security_groups = [aws_security_group.public.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/var/www/html/index.nginx-debian.html"
    interval            = 30
  }

  instances                   = [aws_instance.db_app[0].id,aws_instance.db_app[1].id]
  cross_zone_load_balancing   = true
  idle_timeout                = 100
  connection_draining         = true
  connection_draining_timeout = 300

  tags = {
    Name = "terraform-elb"
  }
}
