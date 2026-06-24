terraform {
  required_version = ">= 1.0.0" # Good practice to lock down your expected CLI version

  # This tells Terraform to store state remotely instead of on your local laptop
  backend "gcs" {
    bucket = "sola-126199-bucket"       # Your GCS bucket name
    prefix = "state/terraform.tfstate"  # The path directory inside your GCS bucket
  }

  # Defines the cloud plugins needed for this infrastructure
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"                # Updated to the latest stable major version constraint
    }
  }
}