variable "vpc_cidr_block" {
    description = "the cidr block of the VPC"
    type = string
}

variable "private_subnet_list" {
  type    = list(string)
}

variable "public_subnet_list" {
  type    = list(string)
}

variable "route_tables_names_list" {
  type    = list(string)
  default = ["public", "private-a", "private-b"]
}

variable "aws_availability_zones"{}