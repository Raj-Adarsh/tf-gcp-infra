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
