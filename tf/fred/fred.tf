resource "helm_release" "fred" {

  name       = "fred"
  chart      = "../../helmcharts/fred"

  values = [yamlencode({
    frontend = {
      replicaCount =  2
      imageTag     = "0.1.0"
      domain       = "app.fredcorp.uk"
    }

    backend = {
      replicaCount = 2
      imageTag     = "0.1.0"
    }

    db = {
      storage     = "20Gi"
      clusterSize =  3
    }

  })]

}
