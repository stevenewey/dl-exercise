module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id = data.aws_vpc.this.id

  # the Kubernetes API will only be accessible internally
  cluster_endpoint_public_access = false
  control_plane_subnet_ids       = data.aws_subnets.private.ids
  subnet_ids                     = data.aws_subnets.private.ids

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  cluster_addons = {
    eks-pod-identity-agent = {
      most_recent                 = true
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      most_recent                 = true
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      most_recent                 = true
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    coredns = {
      most_recent                 = true
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {
    core = {
      ami_type       = var.core_node_ami_type
      instance_types = var.core_node_instance_types

      min_size     = 3
      max_size     = var.core_node_count
      desired_size = var.core_node_count

      # larger than default disk to give plenty of room for container images and ephemeral state
      disk_size = "80"

      iam_role_additional_policies = {
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

    }
  }

}
