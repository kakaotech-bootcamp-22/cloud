# nginx ingress controller 설치

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "default"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.2"  # 원하는 버전 지정

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.replicaCount"
    value = "2" # 이중화를 위해 2개의 Pod 생성
  }
}
