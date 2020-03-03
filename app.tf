resource "google_compute_address" "default" {
  name   = var.gcp_project
  region = var.gcp_region
}

resource "kubernetes_service" "nginx" {
  metadata {
    namespace = kubernetes_namespace.dev_namespace.metadata.0.name
    name      = "nginx"
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.default.address
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    namespace = kubernetes_namespace.dev_namespace.metadata.0.name
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:1.7.9"
          name  = "nginx"
        }
      }
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sleep 10"
  }
}

output "load-balancer-ip" {
  value = "${google_compute_address.default.address}"
}
