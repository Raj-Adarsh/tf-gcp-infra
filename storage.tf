#Can remove this, update cloud function manually
resource "google_storage_bucket" "bucket" {
  name = "${var.project}-gcloud-serverless-bucket"
  location = "us-east1"
  uniform_bucket_level_access = true
  storage_class = "REGIONAL"
  # provider = google-beta
  encryption {
    default_kms_key_name = google_kms_crypto_key.gcs_key.id
  }
  depends_on = [google_kms_crypto_key_iam_binding.gcs_binding]
}

resource "google_storage_bucket_object" "object" {
  name   = "serverless.zip"
  bucket = google_storage_bucket.bucket.name
  source = var.zip_bucket
}
