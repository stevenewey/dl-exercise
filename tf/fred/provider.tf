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
    key            = "prod/fred.tfstate"
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
      "project" = "fred"
      "stage"   = "production"
      "source"  = "https://github.com/stevenewey/dl-exercise/tf/fred"
    }
  }
}

data "terraform_remote_state" "prodcluster" {
  backend = "s3"
  config = {
    region = "eu-west-1"
    bucket = "fredcorp-tfstate"
    key    = "prod/prodcluster.tfstate"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.prodcluster.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.prodcluster.outputs.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.prodcluster.outputs.cluster_name]
    }
  }
}
