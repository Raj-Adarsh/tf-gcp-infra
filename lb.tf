resource "google_compute_global_address" "lb_ip" {
  name         = "lb-ip"
}

resource "google_compute_health_check" "webapp_health_check" {
  name                = "webapp-health-check"
  check_interval_sec  = var.health_check_interval_sec
  timeout_sec         = var.health_check_timeout_sec
  healthy_threshold   = var.health_check_healthy_th
  unhealthy_threshold = var.health_check_unhealthy_th

  http_health_check {
    port         = 8080
    request_path = "/healthz"
  }
}

resource "google_compute_backend_service" "webapp_backend_service" {
  name                = "webapp-backend-service"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol            = "HTTP"

  health_checks       = [google_compute_health_check.webapp_health_check.id]
  locality_lb_policy  =  var.locality_lb_policy
  session_affinity    = "NONE"
  timeout_sec         = 30

  backend {
    group = google_compute_region_instance_group_manager.webapp_group.instance_group
    balancing_mode  = var.balancing_mode
    capacity_scaler = var.capacity_scaler
  }
}

# URL Map
resource "google_compute_url_map" "webapp_url_map" {
  name            = "webapp-url-map"
  default_service = google_compute_backend_service.webapp_backend_service.self_link
}

# Target HTTP Proxy
resource "google_compute_target_https_proxy" "webapp_https_proxy" {
  name    = "webapp-https-proxy"
  url_map = google_compute_url_map.webapp_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.self_link]
}

# Forwarding Rule
resource "google_compute_global_forwarding_rule" "webapp_forwarding_rule" {
  name       = "webapp-forwarding-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.webapp_https_proxy.id
  ip_address            = google_compute_global_address.lb_ip.id
}