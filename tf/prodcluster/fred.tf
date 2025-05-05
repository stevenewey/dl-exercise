resource "kubernetes_namespace" "prodfred" {
  metadata {
    name = "prodfred"
  }
}

# TODO: We would also create an IAM role and Service Account which can be assumed by our CI jobs for fred deployments
