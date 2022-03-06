##################################################################################
# TERRAFORM CONFIG
##################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.1.0"
    }
  }
  required_version = ">= 0.14.9"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  profile = "myprofile"
  region = var.aws_region
  default_tags {
    tags = {
      Owner = var.Owner
      Purpose = var.Purpose
    }
  }
}