terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.46.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }

  backend "gcs" {
    bucket = ""
    prefix = "streaming"
  }
}

provider "google" {
  project = var.project_id
  region  = var.gcp_region
}

