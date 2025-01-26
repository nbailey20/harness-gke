variable "project_id" {
  description = "GCP project where resources will be deployed"
  type        = string
}

variable "region" {
  description = "GCP region where resources will be deployed"
  type        = string
}

variable "harness_image" {
  description = "Full URL of Harness Open Source image stored in Artifact Registry"
  type        = string
}

variable "node_zones" {
  description = "Zones where GKE nodes should be deployed"
  type        = list(string)
}
