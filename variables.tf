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

variable "gcloud_service_email" {
  description = "Gcloud Service Email."
  type        = string
}

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
