variable "gcp_credentials" {
  description = "GCP credentials needed by google provider"
}

variable "gcp_region" {
  description = "GCP region, e.g. us-east1"
  default     = "us-west1"
}

variable "gcp_zone" {
  description = "GCP zone, e.g. us-east1-a"
  default     = "us-west1-b"
}

variable "gcp_project" {
  description = "GCP project name"
}

variable "initial_node_count" {
  description = "Number of worker VMs to initially create"
  default     = 3
}

variable "master_username" {
  description = "Username for accessing the Kubernetes master endpoint"
  default     = "k8smaster"
}

variable "master_password" {
  description = "Password for accessing the Kubernetes master endpoint"
  default     = "k8smasterk8smaster"
}

variable "node_machine_type" {
  description = "GCE machine type"
  default     = "f1-micro"
}

variable "node_disk_size" {
  description = "Node disk size in GB"
  default     = "10"
}

variable "environment" {
  description = "value passed to Environment tag and used in name of Vault auth backend later"
  default     = "gke-dev"
}

variable "labels" {
  description = "descriptive labels for instances deployed"
  default = {
    "name" : "demo-compute-instance",
    "owner" : "andy-assareh",
    "ttl" : "1",
  }
}

// variable "vault_user" {
//   description = "Vault userid: determines location of secrets and affects path of k8s auth backend"
// }

// variable "vault_addr" {
//   description = "Address of Vault server including port"
// }
