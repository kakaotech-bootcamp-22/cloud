resource "kubernetes_ingress" "api_gateway" {
  metadata {
    name = "api-gateway"
    namespace = "default"

    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "your-domain.com" # 사용할 도메인

      http {
        path {
          path = "/fastapi"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.fastapi.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path = "/springboot"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.springboot.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
