output "instance_name" {
  description = "Name of the created VM instance"
  value       = google_compute_instance.instance.name
}

output "instance_zone" {
  description = "Zone where the VM instance is located"
  value       = google_compute_instance.instance.zone
}

output "instance_id" {
  description = "ID of the created VM instance"
  value       = google_compute_instance.instance.id
}