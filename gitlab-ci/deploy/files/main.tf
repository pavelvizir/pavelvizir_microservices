provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
  credentials = "${file("/srv/server-spawn/project.json")}"
}

resource "google_compute_instance" "gitlab-ci-branch-server" {
  zone         = "${var.zone}"
  name         = "${var.name}"
  machine_type = "${var.machine_type}"
  tags         = ["${var.name}"]

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  metadata {
    ssh-keys = "${var.user}:${file(var.public_key)}"
  }

  network_interface {
    network = "default"
    access_config {}
  }
}

resource "google_compute_firewall" "firewall_gitlab-branch-server" {
  name    = "allow-${var.name}-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80","443","22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.name}"]
}
