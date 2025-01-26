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

resource "kubernetes_namespace_v1" "default" {
  metadata {
    name = "harness-ns"
  }
}

resource "kubernetes_deployment_v1" "default" {
  metadata {
    name      = "harness-gke-deployment"
    namespace = kubernetes_namespace_v1.default.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        app = "harness-gke"
      }
    }

    template {
      metadata {
        labels = {
          app = "harness-gke"
        }
      }

      spec {
        container {
          image = "harness/harness:latest"
          name  = "harness-gke-container"

          port {
            container_port = 3000
            # name           = "harness-gke-svc"
          }
          port {
            container_port = 3022
            # name           = "harness-gke-svc"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "harness-gke-svc"
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }

          volume_mount {
            name       = "docker-sock"
            mount_path = "/var/run/docker.sock"
          }
          volume_mount {
            name       = "harness-data"
            mount_path = "/data"
          }
        }

        volume {
          name = "docker-sock"
          empty_dir {}
        }
        volume {
          name = "harness-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.default.metadata[0].name
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
    name      = "harness-gke-loadbalancer"
    namespace = kubernetes_namespace_v1.default.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.default.spec[0].selector[0].match_labels.app
    }

    port {
      port        = 3000
      target_port = kubernetes_deployment_v1.default.spec[0].template[0].spec[0].container[0].port[0].container_port
    }
    port {
      port        = 3022
      target_port = kubernetes_deployment_v1.default.spec[0].template[0].spec[0].container[0].port[1].container_port
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


resource "kubernetes_persistent_volume_v1" "default" {
  metadata {
    name = "harness-gke-pv"
  }

  spec {
    storage_class_name = "harness-gke-storageclass"
    capacity = {
      storage = "10G"
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      name      = kubernetes_persistent_volume_claim_v1.default.metadata[0].name
      namespace = kubernetes_namespace_v1.default.metadata[0].name
    }
    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        volume_handle = google_compute_region_disk.default.id
        fs_type       = "ext4"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "default" {
  metadata {
    name      = "harness-gke-pvc"
    namespace = kubernetes_namespace_v1.default.metadata[0].name
  }

  spec {
    storage_class_name = "harness-gke-storageclass"
    access_modes       = ["ReadWriteOnce"]
    volume_mode        = "Filesystem"
    resources {
      requests = {
        storage = "10G"
      }
    }
  }
  depends_on = [ google_compute_region_disk.default ]
}
