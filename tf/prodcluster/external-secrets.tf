locals {
  external_secrets_namespace      = "external-secrets"
  secrets_manager_service_account = "eso-secrets-manager"
}

data "aws_iam_policy_document" "external_secrets_secrets_manager" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      # give this role/SA access to shared secrets
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:fredcorp/shared/*",
      # and cluster-specific secrets
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:fredcorp/${module.cluster.cluster_name}/*",
    ]
  }
}

resource "aws_iam_policy" "external_secrets_secrets_manager" {
  policy      = data.aws_iam_policy_document.external_secrets_secrets_manager.json
  description = "Secrets Manager for ${module.cluster.cluster_name}"
  name_prefix = "${module.cluster.cluster_name}-secrets-manager-"
}

module "external_secrets_secrets_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = ">= 5, <6"

  role_name = "${module.cluster.cluster_name}-SecretsManager-IRSA"

  oidc_providers = {
    main = {
      provider_arn               = module.cluster.oidc_provider_arn
      namespace_service_accounts = ["${local.external_secrets_namespace}:${local.secrets_manager_service_account}"]
    }
  }

  role_policy_arns = {
    secrets_manager = aws_iam_policy.external_secrets_secrets_manager.arn
  }
}

resource "kubernetes_namespace" "external-secrets" {
  metadata {
    name = local.external_secrets_namespace
  }
}

resource "kubernetes_service_account" "secrets_manager" {
  metadata {
    namespace = local.external_secrets_namespace
    name      = local.secrets_manager_service_account
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_secrets_secrets_manager_irsa.iam_role_arn
    }
  }
}

resource "helm_release" "external-secrets" {
  name       = "external-secrets"
  namespace  = local.external_secrets_namespace
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.10.5"
  atomic     = true

  depends_on = [kubernetes_namespace.external-secrets]

  values = [yamlencode({
    certController = {
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    }
    webhook = {
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    }
    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  })]
}

resource "kubectl_manifest" "secrets_manager_clustersecretstore" {
  depends_on        = [helm_release.external-secrets]
  server_side_apply = true
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "secrets-manager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = data.aws_region.current.name
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = local.secrets_manager_service_account
                namespace = local.external_secrets_namespace
              }
            }
          }
        }
      }
    }
  })
}

