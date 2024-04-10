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
  # provider = google-beta
  name             = "db-instance-${random_string.db_instance_name.result}"
  database_version = var.database_version
  region           = var.db_region

  encryption_key_name = google_kms_crypto_key.cloudsql_key.id

  settings {
    tier = var.tier
    disk_type = var.db_disk_type
    disk_size = var.db_disk_size
    availability_type = var.availability_type
    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = google_compute_network.cloud_app.self_link
    }
    # disk_encryption_key {
    #   kms_key_name = google_kms_crypto_key.cloudsql_key.self_link
    # }
  }

  deletion_protection  = var.deletion_protection

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_kms_crypto_key_iam_binding.cloudsql_binding
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

resource "google_secret_manager_secret" "db_user" {
  project   = var.project
  secret_id = "db-user"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "db_host" {
  project   = var.project
  secret_id = "db-host"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "db_name" {
  project   = var.project
  secret_id = "db-name"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_user_version" {
  secret      = google_secret_manager_secret.db_user.id
  secret_data = "webapp"
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret_version" "db_host_version" {
  secret      = google_secret_manager_secret.db_host.id
  secret_data = google_sql_database_instance.webapp_instance.ip_address[0].ip_address
}

resource "google_secret_manager_secret_version" "db_database_version" {
  secret      = google_secret_manager_secret.db_name.id
  secret_data = "webapp"
}