resource "google_compute_address" "lb_ip" {
  name         = "lb-ip"
  address_type = "EXTERNAL"
  network_tier = "STANDARD"
  region       = var.region
}

resource "google_compute_region_health_check" "webapp_health_check" {
  name               = "webapp-health-check"
  check_interval_sec = 30
  timeout_sec        = 30
  healthy_threshold  = 2
  unhealthy_threshold = 7

  http_health_check {
    port         = 8080
    request_path = "/healthz"
  }
  region         = var.region 
}

resource "google_compute_region_backend_service" "webapp_backend_service" {
  name             = "webapp-backend-service"
  region           = var.region
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol         = "HTTP"

  health_checks    = [google_compute_region_health_check.webapp_health_check.id]
  session_affinity = "NONE"
  timeout_sec      = 30

  backend {
    group = google_compute_region_instance_group_manager.webapp_group.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# URL Map
resource "google_compute_region_url_map" "webapp_url_map" {
  name            = "webapp-url-map"
  region           = var.region
  default_service = google_compute_region_backend_service.webapp_backend_service.self_link
}

# Target HTTP Proxy
resource "google_compute_region_target_http_proxy" "webapp_http_proxy" {
  name    = "webapp-http-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.webapp_url_map.self_link
}

# Forwarding Rule
resource "google_compute_forwarding_rule" "webapp_forwarding_rule" {
  name       = "webapp-forwarding-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network               = google_compute_network.cloud_app.self_link
  depends_on            = [google_compute_subnetwork.proxy_only]
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.webapp_http_proxy.id
  region                = var.region
  ip_address            = google_compute_address.lb_ip.id
  network_tier          = "STANDARD"
}