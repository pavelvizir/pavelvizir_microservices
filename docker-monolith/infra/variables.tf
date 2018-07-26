variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable name {
  description = "VM Name"
  default     = "docker-host"
}

variable "node_count" {
  description = "VM quantity"
  default = "2"
}

variable "machine_type" {
  description = "GCE Machine Type"
  default = "g1-small"
#  default = "f1-micro"
}

variable image {
  description = "Disk image"
  default = "ubuntu-1604-lts"
}

variable user {
  description = "User for ssh access"
}

variable public_key {
  description = "Path to the public key used for ssh access"
}
