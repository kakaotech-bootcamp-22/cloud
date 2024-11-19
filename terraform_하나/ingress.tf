# ingress 리소스 정의

resource "kubernetes_ingress" "api_ingress" {
  metadata {
    name      = "api-ingress"
    namespace = "default"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      host = "example.com"  # 클러스터 도메인

      http {
        path {
          path     = "/backend"
          path_type = "Prefix"

          backend {
            service {
              name = "backend-service"
              port {
                number = 8080
              }
            }
          }
        }

        path {
          path     = "/ai"
          path_type = "Prefix"

          backend {
            service {
              name = "ai-service"
              port {
                number = 5000
              }
            }
          }
        }
      }
    }
  }
}
