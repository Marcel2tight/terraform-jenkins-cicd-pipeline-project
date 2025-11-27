# https://registry.terraform.io/providers/hashicorp/google/latest/docs
# Terraform Settings Block
# Hashicorp Google Registry: https://registry.terraform.io/providers/hashicorp/google/latest
terraform {
  backend "gcs" {
    bucket = "tf-state-quixotic-sunset-479410-d5"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}


