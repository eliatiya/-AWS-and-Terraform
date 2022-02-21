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
resource "aws_instance" "myec2" {
	count         = 2
	ami           = "ami-0892d3c7ee96c0bf7" 
	instance_type = "t3.micro"
	key_name = "develop"
	vpc_security_group_ids = [aws_security_group.web-sg.id]
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

resource "aws_security_group" "web-sg" {
  ingress {
	from_port   = 80
	to_port     = 80
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
	from_port   = 0
	to_port     = 0
	protocol    = "-1"
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
  egress {
	from_port   = 22
	to_port     = 22
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
	from_port   = 80
	to_port     = 80
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
  
}
