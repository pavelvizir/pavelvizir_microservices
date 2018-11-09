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
}

variable "machine_type" {
  description = "GCE Machine Type"
  default = "n1-standard-1"
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
