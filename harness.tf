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
  count = var.sleep_mode ? 0 : 1

  metadata {
    name = "harness-ns"
  }

  ## ensure that k8s resources are cleaned up before pool is deleted 
  ## otherwise TF will keep trying to destroy resources when node is gone
  depends_on = [ google_container_node_pool.default ]
}

resource "kubernetes_deployment_v1" "default" {
  count = var.sleep_mode ? 0 : 1

  metadata {
    name      = "harness-gke-deployment"
    namespace = kubernetes_namespace_v1.default[0].metadata[0].name
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
            name           = "harness-3000"
          }
          port {
            container_port = 3022
            name           = "harness-3022"
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
            name       = "harness-data"
            mount_path = "/data"
          }
          env {
            name  = "DOCKER_HOST"
            value = "tcp://localhost:2375"
          }
        }
        container {
          image = "docker:dind"
          name  = "dind"
          security_context {
            privileged = true
          }
          port {
            container_port = 2375
            name           = "dind-2375"
          }
          volume_mount {
            name       = "docker-graph-storage"
            mount_path = "/var/lib/docker"
          }
          env {
            name  = "DOCKER_TLS_CERTDIR"
            value = ""
          }
        }

        volume {
          name = "docker-graph-storage"
          empty_dir {}
        }
        volume {
          name = "harness-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.default[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "default" {
  count = var.sleep_mode ? 0 : 1

  metadata {
    name      = "harness-gke-loadbalancer"
    namespace = kubernetes_namespace_v1.default[0].metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.default[0].spec[0].selector[0].match_labels.app
    }

    port {
      name        = "harness-3000"
      port        = 3000
      target_port = kubernetes_deployment_v1.default[0].spec[0].template[0].spec[0].container[0].port[0].container_port
    }
    port {
      name        = "harness-3022"
      port        = 3022
      target_port = kubernetes_deployment_v1.default[0].spec[0].template[0].spec[0].container[0].port[1].container_port
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_persistent_volume_v1" "default" {
  count = var.sleep_mode ? 0 : 1

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
      name      = "harness-gke-pvc"
      namespace = kubernetes_namespace_v1.default[0].metadata[0].name
    }
    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        volume_handle = google_compute_disk.default.id
        fs_type       = "ext4"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "default" {
  count = var.sleep_mode ? 0 : 1

  metadata {
    name      = "harness-gke-pvc"
    namespace = kubernetes_namespace_v1.default[0].metadata[0].name
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
  depends_on = [google_compute_disk.default, kubernetes_persistent_volume_v1.default]
}
