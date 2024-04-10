locals {
  timestamp_sanitized = replace(timestamp(), ":", "-")
}

resource "google_kms_key_ring" "keyring" {
  name     = "${var.keyring_name}-${local.timestamp_sanitized}"
  location =  var.region
  project  = var.project
  provider = google-beta
}

resource "google_kms_crypto_key" "compute_key" {
  name            = "compute-key"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = var.rotation_period
  purpose  = var.purpose
  provider = google-beta
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "cloudsql_key" {
  name            = "cloudsql-key"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = var.rotation_period
  purpose  = var.purpose
  provider = google-beta
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "gcs_key" {
  name            = "gcskey"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = var.rotation_period
  purpose  = var.purpose
  provider = google-beta
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret" "vm_secret" {
  project     = var.project
  secret_id   = "vm-key"
  replication {
     auto {}
  }
}

resource "google_secret_manager_secret_version" "vm_secret_version" {
  secret      = google_secret_manager_secret.vm_secret.id
  secret_data = google_kms_crypto_key.compute_key.id
}
