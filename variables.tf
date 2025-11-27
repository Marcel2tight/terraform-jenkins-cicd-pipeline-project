# These feed INTO the module. These are the ACTUAL variables used in root configuration
variable "dev-vm-name" {
  type    = string  
  default = "terraform-vm"
}

variable "dev-vm-machine-type" {
  type    = string  
  default = "e2-medium"
}

variable "dev-vm-az" {
  type    = string  
  default = "us-central1-a"
}

variable "dev-vm-image" {
  type    = string  
  default = "debian-cloud/debian-12"
}

variable "dev-vm-network" {
  type    = string  
  default = "default"
}

variable "project_id" {
  type    = string
  default = "quixotic-sunset-479410-d5"
}