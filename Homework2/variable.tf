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