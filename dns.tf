resource "google_dns_record_set" "cloud_dns" {
  name         = var.custom_dns_name
  type         = "A"
  ttl          = var.ttl
  managed_zone = var.dns_zone
  rrdatas      = [google_compute_instance.webapp_compute_engine.network_interface[0].access_config[0].nat_ip]

  depends_on = [google_compute_instance.webapp_compute_engine]
}
