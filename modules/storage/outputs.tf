output "bucket_names" {
  description = "Names of the created storage buckets"
  value       = google_storage_bucket.buckets[*].name
}

output "bucket_urls" {
  description = "URLs of the created storage buckets"
  value       = google_storage_bucket.buckets[*].url
}