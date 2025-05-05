module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.36.0"

  cluster_name = module.cluster.cluster_name

  enable_pod_identity             = true
  create_pod_identity_association = true

  # Since Karpenter is running on an EKS Managed Node group,
  # we can re-use the role that was created for the node group
  create_access_entry  = false
  create_node_iam_role = false
  node_iam_role_arn    = module.cluster.eks_managed_node_groups.core.iam_role_arn
}

locals {
  karpenter_version = "1.4.0"
}

resource "helm_release" "karpenter" {

  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  name       = "karpenter"
  namespace  = "kube-system"
  version    = local.karpenter_version

  depends_on = [
    module.cluster,
  ]

  values = [yamlencode({
    controller = {
      resources = {
        requests = {
          cpu    = "300m"
          memory = "512Mi"
        }
      }
    }
    serviceMonitor = {
      enabled = true
    }
    settings = {
      clusterName       = module.cluster.cluster_name
      clusterEndpoint   = module.cluster.cluster_endpoint
      interruptionQueue = module.karpenter.queue_name
    }
  })]

}
