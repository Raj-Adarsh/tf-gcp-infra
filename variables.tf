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

variable "internet_access_tags" {
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
