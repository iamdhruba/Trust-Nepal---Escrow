terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "nepaltrust-terraform-state-${random_id.state_suffix.hex}"
    key            = "production/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "nepaltrust-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "NepalTrust"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

resource "random_id" "state_suffix" {
  byte_length = 4
}
