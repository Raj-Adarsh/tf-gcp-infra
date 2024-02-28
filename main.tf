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
  priority     = 999
  source_ranges = ["0.0.0.0/0"]
  #target_tags  = var.internet_access_tags
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

resource "random_string" "db_instance_name" {
  length  = 10
  special = false
  upper   = false
  numeric  = true
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "google_sql_database_instance" "webapp_instance" {
  name             = "db-instance-${random_string.db_instance_name.result}"
  database_version = var.database_version
  region           = var.db_region

  settings {
    tier = var.tier
    disk_type = var.db_disk_type
    disk_size = var.db_disk_size
    availability_type = var.availability_type
    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = google_compute_network.cloud_app.self_link
    }
  }

  deletion_protection  = var.deletion_protection

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

resource "google_sql_database" "webapp_database" {
  name     = "webapp"
  instance = google_sql_database_instance.webapp_instance.name
}

resource "google_sql_user" "webapp_user" {
  name      = "webapp"
  instance = google_sql_database_instance.webapp_instance.name
  password = random_password.db_password.result
}

resource "google_secret_manager_secret" "db_password" {
  project   = var.project
  secret_id = "db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
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

  metadata = {
  startup-script = <<-EOT
    #!/bin/bash
    # Fetch secrets from Google Cloud Secret Manager
    if [ ! -f /etc/webapp.flag ]; then
      echo "DB_USER=webapp" > /etc/webapp.env
      echo "DB_PASSWORD=${random_password.db_password.result}" >> /etc/webapp.env
      echo "DB_NAME=webapp" >> /etc/webapp.env
      echo "DB_HOST=${google_sql_database_instance.webapp_instance.ip_address[0].ip_address}" >> /etc/webapp.env
      sudo chown csye6225:csye6225 /etc/systemd/system/webapp.service
      sudo touch /etc/webapp.flag
    else
      echo "/etc/webapp.flag exists, skipping script execution."
    fi
  EOT
}

  depends_on = [
    google_compute_network.cloud_app,
    google_sql_database_instance.webapp_instance
  ]
}

#test1
resource "google_compute_instance" "webapp_compute_engine_test-1" {
  name         = "webapp-compute-engine-test-1"
  machine_type = var.machine_type
  zone         = var.zone

  #tags = var.internet_access_tags
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

  metadata = {
  startup-script = <<-EOT
    #!/bin/bash
    # Fetch secrets from Google Cloud Secret Manager
    if [ ! -f /etc/webapp.flag ]; then
      #DB_USER=$(gcloud secrets versions access latest --secret="db-username")
      #DB_PASSWORD=$(gcloud secrets versions access latest --secret="db-password")
      #DB_NAME=$(gcloud secrets versions access latest --secret="db-name")
      #DB_HOST=$(gcloud sql instances describe [INSTANCE_ID] --format='get(ipAddresses[0].ipAddress)')

      echo "DB_USER=webapp" > /etc/webapp.env
      echo "DB_PASSWORD=${random_password.db_password.result}" >> /etc/webapp.env
      echo "DB_NAME=webapp" >> /etc/webapp.env
      echo "DB_HOST=${google_sql_database_instance.webapp_instance.ip_address[0].ip_address}" >> /etc/webapp.env
      
      #TMP_SERVICE_FILE="/tmp/webapp.service"

      #sudo cp /etc/systemd/system/webapp.service "$TMP_SERVICE_FILE"
      
      #REMOVE SUDO
      # Replace placeholders with actual values in the temporary file
      #sudo sed -i "s|\\$${DB_USER}|$${DB_USER}|g" "$$TMP_SERVICE_FILE"
      #sudo sed -i "s|\\$${DB_HOST}|$${DB_HOST}|g" "$$TMP_SERVICE_FILE"
      #sudo sed -i "s|\\$${DB_PASSWORD}|$${DB_PASSWORD}|g" "$$TMP_SERVICE_FILE"
      #sudo sed -i "s|\\$${DB_NAME}|$${DB_NAME}|g" "$$TMP_SERVICE_FILE"

      #echo "DB_USER=$DB_USER" > /etc/webapp.env
      #echo "DB_PASSWORD=$DB_PASSWORD" >> /etc/webapp.env
      #echo "DB_NAME=$DB_NAME" >> /etc/webapp.env
      #echo "DB_HOST=$DB_HOST" >> /etc/webapp.env

      #sudo mv "$TMP_SERVICE_FILE" /etc/systemd/system/webapp.service
      sudo chown csye6225:csye6225 /etc/systemd/system/webapp.service
      sudo touch /etc/webapp.flag
    else
      echo "/etc/webapp.flag exists, skipping script execution."
    fi
  EOT
}

  depends_on = [
    google_compute_network.cloud_app,
    #google_secret_manager_secret_version.db_username_version,
    google_secret_manager_secret_version.db_password_version,
    google_sql_database_instance.webapp_instance
  ]
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

  target_tags   = var.internet_access_tags
  depends_on = [google_sql_database_instance.webapp_instance]
}

resource "google_compute_firewall" "deny_all" {
  name                    = "deny-all"
  network                 = google_compute_network.cloud_app.id
  direction               = "EGRESS"
  destination_ranges      = ["0.0.0.0/0"]
  priority                = 1000
  project                 = var.project

  deny {
    protocol = "all"
  }
  depends_on = [google_sql_database_instance.webapp_instance] 
}
