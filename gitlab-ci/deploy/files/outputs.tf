output "gitlab-ci-branch-server_external_ip" {
  value = "${google_compute_instance.gitlab-ci-branch-server.network_interface.0.access_config.0.assigned_nat_ip}"
}
