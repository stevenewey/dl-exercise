resource "kubectl_manifest" "defaul-node-class" {

  depends_on = [helm_release.karpenter]

  server_side_apply = true
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      subnetSelectorTerms = [
        {
          tags = { "karpenter.sh/discovery/prod" = "true" }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = { "karpenter.sh/discovery" = module.cluster.cluster_name }
        }
      ]
      metadataOptions = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = "disabled"
        httpPutResponseHopLimit = 2
        httpTokens              = "required"
      }
      role      = module.cluster.eks_managed_node_groups.core.iam_role_arn
      amiFamily = "AL2023"
    }
  })
}

resource "kubectl_manifest" "defaul-node-pool" {

  depends_on = [kubectl_manifest.defaul-node-class]

  server_side_apply = true
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        spec = {
          expireAfter = "Never"
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
          # limit the instance types we get to recent, high performance options
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "karpenter.k8s.aws/instance-generation"
              operator = "Gt"
              values   = ["5"]
            }
          ]
        }
      }
      disruption = {
        # remove a node that's been emptied after 10 minutes (instead of immediately)
        # in case we need to scale up again quickly
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "10m"
      }
      weight = 10
    }
  })
}
