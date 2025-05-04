terraform {
  required_version = ">=1.11, <2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }
  backend "s3" {
    # terraform state bucket created outside the scope of this repo
    bucket         = "fredcorp-tfstate"
    key            = "prod/common.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    use_lockfile   = true
  }
}

provider "aws" {
  region = "eu-west-1"
  default_tags {
    # automatically tag all created resources with the project, stage and repo
    tags = {
      "project" = "common"
      "stage"   = "production"
      "source"  = "https://github.com/stevenewey/dl-exercise/tf/common"
    }
  }
}

