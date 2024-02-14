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
