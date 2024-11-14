provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = var.cluster_token
}

resource "kubernetes_namespace" "backend" {
  metadata {
    name = "backend"
  }
}

resource "kubernetes_deployment" "backend_server" {
  metadata {
    name      = "backend-server"
    namespace = kubernetes_namespace.backend.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backend-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend-server"
        }
      }

      spec {
        container {
          image = var.backend_image
          name  = "backend-server"

          port {
            container_port = 8080
          }

          env {
            name  = "DB_HOST"
            value = var.db_host
          }

          env {
            name  = "DB_PORT"
            value = var.db_port
          }

          env {
            name  = "DB_NAME"
            value = var.db_name
          }

          env {
            name  = "DB_USER"
            value = var.db_user
          }

          env {
            name  = "DB_PASSWORD"
            value = var.db_password
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend_server" {
  metadata {
    name      = "backend-server-service"
    namespace = kubernetes_namespace.backend.metadata[0].name
  }

  spec {
    selector = {
      app = "backend-server"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}