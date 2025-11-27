variable "name" {
  type        = string
  description = "Name of the VM instance"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the VM"
  default     = "e2-medium"
}

variable "zone" {
  type        = string
  description = "Zone where the VM will be created"
}

variable "image" {
  type        = string
  description = "Boot disk image"
  default     = "debian-cloud/debian-12"
}

variable "network" {
  type        = string
  description = "Network for the VM"
  default     = "default"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}