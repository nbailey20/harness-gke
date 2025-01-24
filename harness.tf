data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth[0].cluster_ca_certificate)

  ignore_annotations = [
    "^autopilot\\.gke\\.io\\/.*",
    "^cloud\\.google\\.com\\/.*"
  ]
}

resource "kubernetes_deployment_v1" "default" {
  metadata {
    name = "example-harness-app-deployment"
  }

  spec {
    selector {
      match_labels = {
        app = "harness-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "harness-app"
        }
      }

      spec {
        container {
          image = "us-docker.pkg.dev/google-samples/containers/gke/harness-app:2.0" ## TODO Create docker image with Harness Open Source
          name  = "harness-app-container"

          port {
            container_port = 8080
            name           = "harness-app-svc"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "harness-app-svc"
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }

        # # Toleration is currently required to prevent perpetual diff:
        # # https://github.com/hashicorp/terraform-provider-kubernetes/pull/2380
        # toleration {
        #   effect   = "NoSchedule"
        #   key      = "kubernetes.io/arch"
        #   operator = "Equal"
        #   value    = "amd64"
        # }
      }
    }
  }
}

resource "kubernetes_service_v1" "default" {
  metadata {
    name = "example-harness-app-loadbalancer"
    # annotations = {
    #   "networking.gke.io/load-balancer-type" = "Internal" # Remove to create an external loadbalancer
    # }
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.default.spec[0].selector[0].match_labels.app
    }

    port {
      port        = 80
      target_port = kubernetes_deployment_v1.default.spec[0].template[0].spec[0].container[0].port[0].name
    }

    type = "LoadBalancer"
  }

#   depends_on = [time_sleep.wait_service_cleanup]
}

# Provide time for Service cleanup
# resource "time_sleep" "wait_service_cleanup" {
#   depends_on = [google_container_cluster.default]

#   destroy_duration = "180s"
# }