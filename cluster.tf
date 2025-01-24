terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = var.gcp_provider_version
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}


resource "google_compute_network" "default" {
  name = "example-network"
  auto_create_subnetworks  = false
}

resource "google_compute_subnetwork" "default" {
  name = "example-subnetwork"

  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.default.id
}

resource "google_container_cluster" "default" {
  name = "example-autopilot-cluster"

  enable_autopilot = true
  network          = google_compute_network.default.id
  subnetwork       = google_compute_subnetwork.default.id

  # Set `deletion_protection` to `true` will ensure that one cannot
  # accidentally delete this instance by use of Terraform.
  deletion_protection = false
}
