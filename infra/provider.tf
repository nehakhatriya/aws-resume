terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
#   backend "s3" {
#     bucket = "neha-resume"
#     key    = "infra/state_file.tfstate"
#     region = "us-east-2"
#   }
}

provider "aws" {
    profile = "aws-resume"
    region = "us-east-2"
}



