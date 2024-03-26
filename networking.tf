resource "google_compute_network" "cloud_app" {
  name                            = var.network_name
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp" {
  name          = var.webapp_subnet_name
  ip_cidr_range = var.webapp_subnet_cidr
  region        = var.region
  network       = google_compute_network.cloud_app.self_link
}

resource "google_compute_subnetwork" "db" {
  name          = var.db_subnet_name
  ip_cidr_range = var.db_subnet_cidr
  region        = var.region
  network       = google_compute_network.cloud_app.self_link
}

resource "google_compute_route" "webapp_internet" {
  name             = var.internet_route_name
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.cloud_app.name
  next_hop_gateway = "default-internet-gateway"
  priority         = var.internet_route_priority
  tags             = var.access_tags
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.cloud_app.name
  project = var.project
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  direction    = "INGRESS"
  priority     = 999
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "deny_ssh" {
  name    = "deny-ssh"
  network = google_compute_network.cloud_app.name
  project = var.project
  deny {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction    = "INGRESS"
  priority     = 1000
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_webapp_egress_to_cloud_sql" {
  name    = "allow-webapp-egress-to-cloud-sql"
  network = google_compute_network.cloud_app.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  direction           = "EGRESS"
  destination_ranges  = ["0.0.0.0/0"]
  priority            = 900

  target_tags   = var.access_tags
  depends_on = [google_sql_database_instance.webapp_instance]
}

resource "google_vpc_access_connector" "vpc_connector" {
  name          = "vpc-connector"
  project       = var.project
  region        = var.region
  network       = google_compute_network.cloud_app.name
  ip_cidr_range = var.vpc_connector_ip
}

resource "google_compute_global_address" "private_services_range" {
  project      = var.project
  name         = "private-services-range"
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16
  network      = google_compute_network.cloud_app.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.cloud_app.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services_range.name]
}
