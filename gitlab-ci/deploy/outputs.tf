output "gitlab-ci-host_external_ip" {
  value = "${google_compute_instance.gitlab-ci-host.*.network_interface.0.access_config.0.assigned_nat_ip}"
}
