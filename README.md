# Simple CI/CD Pipeline

Repo contains everything needed to stand up a CI/CD pipeline hosted in GKE that integrates with GitHub repositories.

High-Level Setup Steps:
* Apply Terraform module to create GKE cluster
* Install Helm chart to deploy Harness Open Source pod
* Create project and pipeline in Harness, integrate with Github repo
* Create Docker snapshot once Harness is fully setup, update Helm chart with pre-configured image
* Trigger pipeline with commits in Github
* Use Helm to scale down Harness pod when not in use


## Prerequisite
* GCP Project and gcloud installed