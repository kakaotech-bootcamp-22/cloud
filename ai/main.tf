provider "kubernetes" {
  config_path = module.eks.kubeconfig
}

resource "kubernetes_deployment" "ai" {
  metadata {
    name      = "ai-deployment"
    namespace = "default"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "ai"
      }
    }

    template {
      metadata {
        labels = {
          app = "ai"
        }
      }

      spec {
        container {
          name  = "ai"
          image = "my-ai-image:latest"
          ports {
            container_port = 5000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "ai" {
  metadata {
    name      = "ai-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "ai"
    }
    type = "ClusterIP"
    ports {
      port        = 80
      target_port = 5000
    }
  }
}