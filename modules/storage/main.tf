resource "google_storage_bucket" "buckets" {
  count         = length(var.bucket_names)
  project       = var.project_id
  name          = var.bucket_names[count.index]
  location      = var.location
  force_destroy = var.force_destroy
}