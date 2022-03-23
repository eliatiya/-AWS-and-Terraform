terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.3"
    }
  }
  cloud {
    hostname     = "app.terraform.io"
    organization = "example-org-a7ff27"
    workspaces {
      name = "webserver_opsschool_qa"
    }
  }
  required_version = ">= 0.14.9"
}

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
