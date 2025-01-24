# Simple CI/CD Pipeline

Repo contains everything needed to stand up a CI/CD pipeline hosted in GKE that integrates with GitHub repositories.

High-Level Setup Steps:
* Apply Terraform script to create GKE cluster, Artifact Registry, and Harness Open Source pods
* Create project and pipeline in Harness, import Github repo
* Clone Harness repo locally
* Create custom Docker image once Harness is fully setup
* Push custom image to Artifact Registry
* Update Terraform with pre-configured image location and reapply
* Trigger pipeline with commits in Harness repo (Harness Open Source doesn't support GitHub triggers)
* Use Helm to scale down Harness pod when not in use


## Prerequisite
* GCP Project and gcloud installed