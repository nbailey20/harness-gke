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

variable "node_zone" {
  description = "GCP zone where GKE node should be deployed"
  type        = string
}

variable "sleep_mode" {
  description = "Boolean indicating whether pipeline is actively being used, if true then K8s resources / cluster node will be removed for $$ savings"
  type        = bool
  default     = false
}
