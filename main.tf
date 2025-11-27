# VM Instance using module
module "vm_instance" {
  source = "./modules/vm"

  name         = var.dev-vm-name
  machine_type = var.dev-vm-machine-type
  zone         = var.dev-vm-az
  image        = var.dev-vm-image
  network      = var.dev-vm-network
  project_id   = var.project_id
}

# Storage Buckets using module
module "storage_buckets" {
  source = "./modules/storage"

  bucket_names = [for i in range(2) : "prod-no-public-access-bucket-po-${i}"]
  location     = "US"
  project_id   = var.project_id
  force_destroy = true
}