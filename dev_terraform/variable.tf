variable "Owner" {
  type = string
  default = "eliezer"
}
variable "Purpose" {
  type = string
  default = "Whiskey Shop"
}
variable "enviroment" {
  type = string
}
variable "aws_region" {
  type        = string
  description = "Region for AWS Resources"
  default     = "us-west-2"
}
variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create"
  default = "eliezer-bucket"
}

variable "public_subnets_cidr" {
  type    = list
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "availability_zones" {
  type    = list
  default = ["us-west-2a", "us-west-2b"]
}

variable "private_availability_zones" {
  type    = list
  default = ["us-west-2c","us-west-2d"]
}
variable "private_subnets_cidr" {
  type    = list
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}
variable "instance_count" {
  type        = number
  description = "Number of instances to create in VPC"
  default     = 2
}

variable "instance_ami" {
  type    = string
  default = "ami-0892d3c7ee96c0bf7"
}

variable "vpc_cidr_block" {
  type        = string
  description = "Base CIDR Block for VPC"
  default = "10.0.0.0/16"
}
variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in VPC"
  default     = true
}
