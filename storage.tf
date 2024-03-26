#Can remove this, update cloud function manually
resource "google_storage_bucket" "bucket" {
  name = "${var.project}-gcloud-serverless-bucket"
  location = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "object" {
  name   = "serverless.zip"
  bucket = google_storage_bucket.bucket.name
  source = var.zip_bucket
}
