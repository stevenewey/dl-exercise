locals {
  aws_lbc_service_account = "aws-load-balancer-controller"
}

module "aws_lbc_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = ">= 5, <6"

  role_name                              = "${module.cluster.cluster_name}-AWS-LoadBalancerController-IRSA"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:${local.aws_lbc_service_account}"]
    }
  }
}

resource "kubernetes_service_account" "aws_lbc" {
  metadata {
    name      = local.aws_lbc_service_account
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.aws_lbc_irsa.iam_role_arn
    }
  }
}

resource "helm_release" "aws_lbc" {

  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.12.0"
  atomic     = true

  values = [yamlencode({
    region      = data.aws_region.current.name
    vpcId       = data.aws_vpc.this.id
    clusterName = module.cluster.cluster_name
    resources = {
      requests = {
        cpu    = "10m"
        memory = "48Mi"
      }
    }
    serviceAccount = {
      name   = local.aws_lbc_service_account
      create = false
    }
    serviceMonitor = {
      enabled = true
    }
  })]

  depends_on = [
    module.cluster,
    kubernetes_service_account.aws_lbc,
  ]
}
