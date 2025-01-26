terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
    kubernetes = {
        source  = "hashicorp/kubernetes"
        version = "2.35.1"
    }
  }
}
