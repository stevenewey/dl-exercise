module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name                  = "fredcorp-prod"
  cidr                  = "10.100.0.0/16"

  azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  # large internal subnets (16k hosts) to ensure sufficient IPs for all hosts and pods
  private_subnets = ["10.100.0.0/18", "10.100.64.0/18", "10.100.128.0/18"]
  private_subnet_tags = {
    # used by karpenter to discover which subnets instances should be created in
    "karpenter.sh/discovery/prod" : "true",
  }

  # smaller public subnets, used only by NAT gateways, external ELBs and VPN/bastion hosts
  public_subnets = ["10.100.192.0/24", "10.100.193.0/24", "10.100.194.0/24"]
  public_subnet_tags = {
    # used by the AWS Load Balancer controller to identify subnets suitable for created ELBs
    "kubernetes.io/role/elb" : 1,
  }
  map_public_ip_on_launch = true

  enable_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true
}

