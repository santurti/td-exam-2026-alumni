terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.5.0"
    }
  }
}

provider "google" {
  credentials = file("repaso-examen-500009-69c076cf21ab.json")

  project = var.gcp-project
  region  = var.gcp-region
  zone    = var.gcp-zone
}
