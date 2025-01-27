# Simple CI/CD Pipeline

Repo contains everything needed to stand up a CI/CD pipeline hosted in GKE that integrates with GitHub repositories.

High-Level Setup Steps:
* Apply Terraform script
    * GCP provider will create GKE cluster, Artifact Registry, Persistent Disk
    * Kubernetes provider will create Persistent Volume, Persistent Volume Claim, Harness Open Source pod
* Login to Harness with provided IP from Terraform output
* Create project and pipeline in Harness, import Github repo
* Clone Harness repo locally
* Trigger pipeline with commits in Harness repo (Harness Open Source doesn't support GitHub triggers)
* Update var.sleep_mode to delete node pool when not actively in use (save $$)


## Prerequisite
* GCP Project and gcloud installed
* Run this gcloud command to allow Terraform to perform actions on your behalf: 
    gcloud auth application-default login
* Run this command to authenticate with kubectl for GKE troubleshooting: 
    gcloud container clusters get-credentials example-autopilot-cluster --region region --project prj-id