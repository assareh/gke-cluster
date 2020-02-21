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

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = var.gcp_zone
  cluster    = google_container_cluster.default.name
  node_count = 4

  node_config {
    preemptible  = true
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size
  }
}

provider "kubernetes" {
  #version                = "1.10.0"
  load_config_file       = "false"
  host                   = "https://${google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.current.access_token
  client_certificate     = base64decode(google_container_cluster.default.master_auth.0.client_certificate)
  client_key             = base64decode(google_container_cluster.default.master_auth.0.client_key)
  cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "dev_namespace" {
  metadata {
    name = "development"
  }
}

resource "kubernetes_resource_quota" "example" {
  metadata {
    name = "quota-example"
    namespace = kubernetes_namespace.dev_namespace.metadata.0.name
  }

  spec {
    hard = {
      pods = 6
    }

    scopes = ["BestEffort"]
  }
}

output "cluster_name" {
  value = google_container_cluster.default.name
}

output "cluster_region" {
  value = google_container_cluster.default.location
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

output "cluster_namespace" {
  value = kubernetes_namespace.dev_namespace.metadata.0.name
}
