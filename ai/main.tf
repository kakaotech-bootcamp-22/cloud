provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = var.cluster_token
}

resource "kubernetes_namespace" "ai" {
  metadata {
    name = "ai"
  }
}

resource "kubernetes_deployment" "ai_server" {
  metadata {
    name      = "ai-server"
    namespace = kubernetes_namespace.ai.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ai-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "ai-server"
        }
      }

      spec {
        container {
          image = var.ai_image
          name  = "ai-server"

          port {
            container_port = 8000
          }

          env {
            name  = "AWS_REGION"
            value = var.aws_region
          }

          env {
            name  = "S3_BUCKET_NAME"
            value = var.s3_bucket_name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "ai_server" {
  metadata {
    name      = "ai-server-service"
    namespace = kubernetes_namespace.ai.metadata[0].name
  }

  spec {
    selector = {
      app = "ai-server"
    }

    port {
      port        = 8000
      target_port = 8000
    }

    type = "ClusterIP"
  }
}