resource "google_pubsub_topic" "pubsub_topic" {
  name = "verify_email"
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
        SENDGRID_API_KEY = var.sendgrid_key
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
    retry_policy = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.service_account_cloud_function.email
  }

  depends_on = [google_sql_database_instance.webapp_instance]
}
