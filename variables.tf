variable "project" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
}

variable "network_name" {
  description = "The name of the network."
  type        = string
}

variable "webapp_subnet_name" {
  description = "The name of the webapp subnet."
  type        = string
}

variable "webapp_subnet_cidr" {
  description = "The CIDR block for the webapp subnet."
  type        = string
}

variable "db_subnet_name" {
  description = "The name of the db subnet."
  type        = string
}

variable "db_subnet_cidr" {
  description = "The CIDR block for the db subnet."
  type        = string
}

variable "internet_route_name" {
  description = "The name of the internet route."
  type        = string
}

variable "internet_route_priority" {
  description = "The priority of the internet route."
  type        = number
}

variable "access_tags" {
  description = "Tags for VMs that should have internet access."
  type        = list(string)
}

variable "routing_mode" {
  description = "Routing region of the VPC."
  type        = string
}

variable "image" {
  description = "Packer Custom Image."
  type        = string
}

variable "type" {
  description = "Disk Type of boot Disk."
  type        = string
}

variable "disk_size" {
  description = "Disk Size of the machine."
  type        = number
}

#variable "gcloud_service_email" {
#  description = "Gcloud Service Email."
#  type        = string
#}

variable "machine_type" {
  description = "Machine type of the VM."
  type        = string
}

variable "zone" {
  description = "Zone of the VM."
  type        = string
}


variable "db_disk_size" {
  description = "SQL instance disk size."
  type        = number
}

variable "db_disk_type" {
  description = "SQL instance disk type"
  type        = string
}

variable "ipv4_enabled" {
  description = "IPv4 enabled."
  type        = bool
}

variable "db_region" {
  description = "SQL instance region."
  type        = string
}

variable "deletion_protection" {
  description = "Deletion protection of the sql instance."
  type        = bool
}

variable "availability_type" {
  description = "Availibility Type of the sql instance."
  type        = string
}
  
variable "tier" {
  description = "Tier of SQL instance."
  type        = string
}

variable "database_version" {
  description = "PostgresQL version."
  type        = string
}

variable "custom_dns_name" {
  description = "Custom DNS name."
  type        = string
}


variable "dns_zone" {
  description = "DNS zone."
  type        = string
}


variable "account_id" {
  description = "Service Account ID."
  type        = string
}

variable "ttl" {
  description = "TTL for A record."
  type        = number
}

variable "scopes" {
  description = "The scopes for the service account"
  type        = list(string)
  # default     = ["https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/pubsub"]
  default = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.admin", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/pubsub", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]

}

variable "sendgrid_key" {
  description = "SendGrid API Key"
  type        = string
}

variable "zip_bucket" {
  description = "The path for the cloud function zip"
  type        = string
}

variable "vpc_connector_ip" {
  description = "The IP range for VPC connector"
  type        = string
}


variable "locality_lb_policy" {
  description = "The LB policy"
  type        = string
}

variable "health_check_healthy_th"{
  description = "The healthy threshold of health-check"
  type        = number
}

variable "health_check_unhealthy_th" {
  description = "The unhealthy threshold of health-check"
  type        = number
}


variable "health_check_timeout_sec" {
  description = "The health-check timeout in seconds"
  type        = number
}


variable "health_check_interval_sec" {
  description = "The health-check interval in seconds"
  type        = number
}


variable "balancing_mode" {
  description = "The load balancing mode of backend."
  type        = string
}

variable "capacity_scaler" {
  description = "The scaler capacity of backend."
  type        = number
}


variable "max_replicas" {
  description = "The autoscaler max number of instances."
  type        = number
}



variable "min_replicas" {
  description = "The autoscaler min number of instances."
  type        = number
}



variable "target" {
  description = "The target utilisation for autoscaler to scale in-out."
  type        = number
}

variable "health_check_ip1" {
  description = "The Health checkp IP 1."
  type        = string
}

variable "health_check_ip2" {
  description = "The Health checkp IP 2"
  type        = string
}
