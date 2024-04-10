locals {
  timestamp_sanitized = replace(timestamp(), ":", "-")
}

resource "google_kms_key_ring" "keyring" {
  name     = "${var.keyring_name}-${local.timestamp_sanitized}"
  location =  var.region
  project  = var.project
  #provider
  provider = google-beta

#   depends_on = [google_kms_key_ring_iam_binding.key_ring.id, google_kms_crypto_key_iam_binding.compute_key_binding.id, google_kms_crypto_key_iam_binding.cloudsql_binding.id, google_kms_crypto_key_iam_binding.gcs_binding.id]
}

resource "google_kms_crypto_key" "compute_key" {
  name            = "compute-key"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = var.rotation_period
  purpose  = "ENCRYPT_DECRYPT"
  provider = google-beta
  lifecycle {
    prevent_destroy = false
  }

#   depends_on = [google_kms_key_ring_iam_binding.key_ring.id, google_kms_crypto_key_iam_binding.compute_key_binding.id, google_kms_crypto_key_iam_binding.cloudsql_binding.id, google_kms_crypto_key_iam_binding.gcs_binding.id]
}

resource "google_kms_crypto_key" "cloudsql_key" {
  name            = "cloudsql-key"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = var.rotation_period
  purpose  = "ENCRYPT_DECRYPT"
  provider = google-beta
  lifecycle {
    prevent_destroy = false
  }

#   depends_on = [google_kms_key_ring_iam_binding.key_ring.id, google_kms_crypto_key_iam_binding.compute_key_binding.id, google_kms_crypto_key_iam_binding.cloudsql_binding.id, google_kms_crypto_key_iam_binding.gcs_binding.id]
}

resource "google_kms_crypto_key" "gcs_key" {
  name            = "gcskey"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = var.rotation_period
  purpose  = "ENCRYPT_DECRYPT"
  provider = google-beta
  lifecycle {
    prevent_destroy = false
  }
#   depends_on = [google_kms_key_ring_iam_binding.key_ring.id, google_kms_crypto_key_iam_binding.compute_key_binding.id, google_kms_crypto_key_iam_binding.cloudsql_binding.id, google_kms_crypto_key_iam_binding.gcs_binding.id]
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




