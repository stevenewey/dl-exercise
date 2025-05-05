resource "helm_release" "rabbitmq" {

  name       = "rabbitmq"
  namespace  = "prodfred"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "rabbitmq"
  version    = "16.0.1"

  values = [yamlencode({
    replicaCount = 3
    clustering = {
      name = "fredmq"
    }
  })]

}
