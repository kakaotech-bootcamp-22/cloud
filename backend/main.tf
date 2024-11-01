provider "kubernetes" {
  config_path = module.eks.kubeconfig
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend-deployment"
    namespace = "default"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = "my-backend-image:latest"
          ports {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "backend"
    }
    type = "ClusterIP"
    ports {
      port        = 80
      target_port = 8080
    }
  }
}