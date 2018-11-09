resource "google_compute_instance" "gitlab-ci-server-spawn-host" {
  zone         = "${var.zone}"
  name         = "gitlab-ci-server-spawn-host"
  machine_type = "f1-micro"
  tags         = ["gitlab-ci-server-spawn-host"]

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

resource "google_compute_firewall" "firewall_gitlab-ci-server-spawn-host-default" {
  name    = "allow-gitlab-ci-server-spawn-host-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9999","22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitlab-ci-server-spawn-host"]
}
