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
  tags             = var.access_tags
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

  tags = var.access_tags
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
    email  = google_service_account.service_account.email
    scopes = var.scopes
  }

  metadata = {
  startup-script = <<-EOT
    #!/bin/bash
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

resource "google_dns_record_set" "cloud_dns" {
  name         = var.custom_dns_name
  type         = "A"
  ttl          = var.ttl
  managed_zone = var.dns_zone
  rrdatas      = [google_compute_instance.webapp_compute_engine.network_interface[0].access_config[0].nat_ip]

  depends_on = [google_compute_instance.webapp_compute_engine]
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

resource "google_service_account" "service_account" {
  account_id   = var.account_id
  display_name = "Service Account"
  project      = var.project
  create_ignore_already_exists = true
}

resource "google_project_iam_binding" "logging_admin" {
  project = var.project
  role    = "roles/logging.admin"

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
    "serviceAccount:${google_service_account.service_account_cloud_function.email}"
  ]

  lifecycle {
    ignore_changes = [members]
  }
}

resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = var.project
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
    "serviceAccount:${google_service_account.service_account_cloud_function.email}"
  ]

  lifecycle {
    ignore_changes = [members]
  }
}

resource "google_service_account" "service_account_cloud_function" {
  account_id = "cloud-function"
  display_name = "CF Service Account"
  project      = var.project
  create_ignore_already_exists = true
}

resource "google_pubsub_topic" "pubsub_topic" {
  name = "verify_email"
}

#Can remove this, update cloud function manually
resource "google_storage_bucket" "bucket" {
  name = "${var.project}-gcloud-serverless-bucket"
  location = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "object" {
  name   = "serverless.zip"
  bucket = google_storage_bucket.bucket.name
  source = "/Users/adarshraj/Downloads/serverless.zip"
}

resource "google_cloudfunctions2_function" "cloud_function" {
  name = "serverless"
  location = var.region
  description = "A serverless function to send out emails"

  build_config {
    runtime = "go121"
    entry_point = "SendVerificationEmail"
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count  = 0
    min_instance_count = 1
    available_memory    = "256M"
    timeout_seconds     = 60
    max_instance_request_concurrency = 80
    available_cpu = "1"
    environment_variables = {
        DB_USER     = "webapp"
        DB_PASSWORD = "${random_password.db_password.result}"
        DB_NAME     = "webapp"
        DB_HOST     = "${google_sql_database_instance.webapp_instance.ip_address[0].ip_address}"
        SENDGRID_API_KEY = "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"
    }
    ingress_settings = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email = google_service_account.service_account_cloud_function.email
    vpc_connector = google_vpc_access_connector.vpc_connector.name
  }

  event_trigger {
    trigger_region = var.region
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.pubsub_topic.id
    #retry_policy = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.service_account_cloud_function.email
  }

  depends_on = [google_sql_database_instance.webapp_instance]
}

resource "google_cloud_run_service_iam_binding" "cloud_run_invoker" {
  project  = google_cloudfunctions2_function.cloud_function.project
  location = google_cloudfunctions2_function.cloud_function.location
  service  = google_cloudfunctions2_function.cloud_function.name
  role     = "roles/run.invoker"
  members = [
    "serviceAccount:${google_service_account.service_account_cloud_function.email}"
  ]
  lifecycle {
    ignore_changes = [members]
  }
}

resource "google_project_iam_binding" "service_account_sql_client" {
  project = var.project
  role    = "roles/cloudsql.client"
  members = [
    "serviceAccount:${google_service_account.service_account_cloud_function.email}"
  ]
  lifecycle {
    ignore_changes = [members]
  }
}

resource "google_vpc_access_connector" "vpc_connector" {
  name          = "vpc-connector"
  project       = var.project
  region        = var.region
  network       = google_compute_network.cloud_app.name
  ip_cidr_range = "10.0.8.0/28"
}

resource "google_project_iam_binding" "pubsub_publisher" {
  project = var.project
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
  lifecycle {
    ignore_changes = [members]
  }
}
