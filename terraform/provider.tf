# ---------------------------------------------------------------------------------------------------------------------
# AWS PROVIDER FOR TF CLOUD
# ---------------------------------------------------------------------------------------------------------------------

# terraform {
#   required_version = "~>0.12"
# }


provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

terraform {
  required_version = "~> 1.0"
 
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
 
  backend "s3" {
    acl                  = "bucket-owner-full-control"
    bucket               = "sallaman-s3-reviewapps-terraform-petclinic-state-files"
    encrypt              = true
    workspace_key_prefix = "__KEY_PREFIX_NAME__"
    key                  = "__KEY_NAME__.tfstate"
    region               = "eu-west-1"
  }
}