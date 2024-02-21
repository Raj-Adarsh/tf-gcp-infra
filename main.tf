provider "google" {
  project = var.project
  region  = var.region
}

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
  depends_on = [google_compute_network.cloud_app]
}

resource "google_compute_subnetwork" "db" {
  name          = var.db_subnet_name
  ip_cidr_range = var.db_subnet_cidr
  region        = var.region
  network       = google_compute_network.cloud_app.self_link
  depends_on = [google_compute_network.cloud_app]
}

resource "google_compute_route" "webapp_internet" {
  name             = var.internet_route_name
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.cloud_app.name
  next_hop_gateway = "default-internet-gateway"
  priority         = var.internet_route_priority
  tags             = var.internet_access_tags
  depends_on = [google_compute_network.cloud_app]
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
  priority     = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags  = var.internet_access_tags
  depends_on = [google_compute_network.cloud_app]
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
  depends_on = [google_compute_network.cloud_app]
}

resource "google_compute_instance" "webapp_compute_engine" {
  name         = "webapp-compute-engine"
  machine_type = var.machine_type
  zone         = var.zone

  tags = var.internet_access_tags
  boot_disk {
    initialize_params {
      image = var.image
      type  = var.type
      size  = var.disk_size
      
    }
  }

  network_interface {
    network    = google_compute_network.cloud_app.id
    subnetwork = google_compute_subnetwork.webapp.id

    access_config {
      // Ephemeral IP will be assigned by GCP
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = var.gcloud_service_email
    scopes = ["cloud-platform"]
  }
  depends_on = [google_compute_network.cloud_app]
}
