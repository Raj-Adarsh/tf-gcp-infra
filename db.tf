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
