provider "google" {
  project = var.project_id
  region  = var.region
}


resource "google_compute_network" "default" {
  name                    = "example-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name = "example-subnetwork"

  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.default.id
}

resource "google_container_cluster" "default" {
  name = "example-autopilot-cluster"

  network                  = google_compute_network.default.id
  subnetwork               = google_compute_subnetwork.default.id
  node_locations           = [var.node_zone]
  initial_node_count       = 1
  remove_default_node_pool = true

  # Set `deletion_protection` to `true` will ensure that one cannot
  # accidentally delete this instance by use of Terraform.
  deletion_protection = false
}

resource "google_container_node_pool" "default" {
  count = var.sleep_mode ? 0 : 1

  name       = "harness-gke-np"
  cluster    = google_container_cluster.default.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
  }
}

resource "google_compute_disk" "default" {
  name = "harness-gke-pd"
  size = 10
  type = "pd-ssd"
  zone = var.node_zone
}
