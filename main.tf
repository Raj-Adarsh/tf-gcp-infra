provider "google" {
  project = "csye6225-dev-414220"
  region  = "us-east1"
}

resource "google_compute_network" "cloud_app" {
  name                    = "cloud-app"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp" {
  name          = "webapp"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-east1"
  network       = google_compute_network.cloud_app.self_link
}

resource "google_compute_subnetwork" "db" {
  name          = "db"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-east1"
  network       = google_compute_network.cloud_app.self_link
}

resource "google_compute_route" "webapp_internet" {
  name            = "webapp-internet"
  dest_range      = "0.0.0.0/0"
  network         = google_compute_network.cloud_app.name
  next_hop_gateway = "default-internet-gateway"
  priority        = 1000
}

