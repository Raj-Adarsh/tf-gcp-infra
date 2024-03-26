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
