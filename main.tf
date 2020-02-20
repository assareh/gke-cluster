terraform {
  required_version = ">= 0.12"
}

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

// variable "master_username" {
//   description = "Username for accessing the Kubernetes master endpoint"
//   default     = "k8smaster"
// }

// variable "master_password" {
//   description = "Password for accessing the Kubernetes master endpoint"
//   default     = "k8smasterk8smaster"
// }

variable "node_machine_type" {
  description = "GCE machine type"
  default     = "g1-small"
}

variable "node_disk_size" {
  description = "Node disk size in GB"
  default     = "10"
}

variable "labels" {
  description = "descriptive labels for instances deployed"
  default = {
    "name" : "demo-compute-instance",
    "owner" : "andy-assareh",
    "ttl" : "1",
  }
}

provider "google" {
  credentials = var.gcp_credentials
  project     = var.gcp_project
  region      = var.gcp_region
}

data "terraform_remote_state" "network" {
  backend = "remote"

  config = {
    organization = "multicloud-provisioning-demo"
    workspaces = {
      name = "01-gke-network"
    }
  }
}

data "google_client_config" "current" {}

data "google_container_engine_versions" "default" {
  location = var.gcp_zone
}

resource "google_container_cluster" "default" {
  name               = var.gcp_project
  location           = var.gcp_zone
  initial_node_count = 3
  min_master_version = data.google_container_engine_versions.default.latest_master_version
  network            = data.terraform_remote_state.network.outputs.network
  subnetwork         = data.terraform_remote_state.network.outputs.subnetwork_name
  resource_labels    = var.labels

  // Use legacy ABAC until these issues are resolved: 
  //   https://github.com/mcuadros/terraform-provider-helm/issues/56
  //   https://github.com/terraform-providers/terraform-provider-kubernetes/pull/73
  enable_legacy_abac = true

  // Wait for the GCE LB controller to cleanup the resources.
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 90"
  }

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size
  }
}

output "cluster_name" {
  value = google_container_cluster.default.name
}

output "cluster_region" {
  value = google_container_cluster.default.region
}

output "cluster_zone" {
  value = google_container_cluster.default.zone
}

output "cluster_endpoint" {
  value = google_container_cluster.default.endpoint
}

output "cluster_master_version" {
  value = google_container_cluster.default.master_version
}

output "cluster_instance_group_urls" {
  value = google_container_cluster.default.instance_group_urls.0
}

output "cluster_master_auth_client_certificate" {
  value = google_container_cluster.default.master_auth.0.client_certificate
}

output "cluster_master_auth_client_key" {
  value = google_container_cluster.default.master_auth.0.client_key
}

output "cluster_master_auth_cluster_ca_certificate" {
  value = google_container_cluster.default.master_auth.0.cluster_ca_certificate
}

output "cluster_access_token" {
  value = data.google_client_config.current.access_token
}

// resource "google_container_cluster" "k8sexample" {
//   name               = "k8s-cluster-${var.env}"
//   description        = "example k8s cluster"
//   location           = var.gcp_zone
//   initial_node_count = var.initial_node_count
//   enable_legacy_abac = "true"
//   resource_labels    = var.labels

//   master_auth {
//     username = var.master_username
//     password = var.master_password

//     client_certificate_config {
//       issue_client_certificate = true
//     }
//   }

//   network    = data.terraform_remote_state.network.outputs.network_name
//   subnetwork = data.terraform_remote_state.network.outputs.subnet_name[0]

//   node_config {
//     machine_type = var.node_machine_type
//     disk_size_gb = var.node_disk_size
//     oauth_scopes = [
//       "https://www.googleapis.com/auth/compute",
//       "https://www.googleapis.com/auth/devstorage.read_only",
//       "https://www.googleapis.com/auth/logging.write",
//       "https://www.googleapis.com/auth/monitoring"
//     ]
//   }
// }
