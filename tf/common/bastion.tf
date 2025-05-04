data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "bastion" {
  name_prefix = "bastion-sg-"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "bastion_out" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.bastion.id
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

resource "aws_security_group_rule" "bastion_ssh" {
  from_port         = 22
  protocol          = "TCP"
  to_port           = 22
  type              = "ingress"
  security_group_id = aws_security_group.bastion.id
  # limit SSH access to known external IPs
  cidr_blocks       = ["1.2.3.0/24"]
}

module "bastion" {
  # create a bastion instance in the first public subnet to allow remote access to protected resources
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.8.0"

  name               = "bastion"
  instance_type      = "t3a.medium"
  ami                = data.aws_ami.ubuntu.id
  ignore_ami_changes = true

  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = module.vpc.public_subnets[0]

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 30
    }
  ]

  create_iam_instance_profile = true
  iam_role_description        = "Bastion host IAM role"
  iam_role_policies = {
    # allow AWS SSM operation for this instance (preferable to SSH)
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  metadata_options = {
    http_tokens = "required"
  }

  monitoring = true
}

data "aws_route53_zone" "fredcorpinfra" {
  # assuming an existing route53 zone exists for our infra
  name         = "infra.fredcorp.uk"
}

resource "aws_route53_record" "bastion" {
  name    = "bastion-prod"
  type    = "A"
  zone_id = data.aws_route53_zone.fredcorpinfra.zone_id
  records = [module.bastion.public_ip]
  ttl     = 300
}
