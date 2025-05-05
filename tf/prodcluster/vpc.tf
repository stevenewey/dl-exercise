data "terraform_remote_state" "common" {
  backend = "s3"
  config = {
    region = "eu-west-1"
    bucket = "fredcorp-tfstate"
    key    = "prod/common.tfstate"
  }
}

# actively look up the VPC and subnets from the common state, to validate they still exist,
# and in case we need other details about the resources

data "aws_vpc" "this" {
  id = data.terraform_remote_state.common.outputs.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "subnet-id"
    values = data.terraform_remote_state.common.outputs.private_subnet_ids
  }
}
