resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name    = "webapp-cert"
  project = var.project

  managed {
    domains = ["rajadarsh.me"]
  }
}
