variable "bucket_names" {
  type        = list(string)
  description = "List of bucket names"
}

variable "location" {
  type        = string
  description = "Location for the storage buckets"
  default     = "US"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "force_destroy" {
  type        = bool
  description = "Whether to force destroy buckets with content"
  default     = true
}