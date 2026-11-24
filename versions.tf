terraform {
  required_version = "~> 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.8.0"
    }
  }
}

provider "google" {
  project = var.delivery_project_id
  region  = var.region
}
