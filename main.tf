terraform {
  required_version = ">= 0.11.11"
}

provider "google" {
  credentials = "${var.gcp_credentials}"
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
}

// provider "vault" {
//   address = "${var.vault_addr}"
// }

// data "vault_generic_secret" "gcp_credentials" {
//   path = "secret/${var.vault_user}/gcp/credentials"
// }

data "terraform_remote_state" "network" {
  backend = "remote"

  config = {
    organization = "multicloud-provisioning-demo"
    workspaces = {
      name = "gke-network"
    }
  }
}

resource "google_container_cluster" "k8sexample" {
  name               = format("%s-%s", "k8s-cluster", var.env)
  description        = "example k8s cluster"
  location           = "${var.gcp_zone}"
  initial_node_count = "${var.initial_node_count}"
  enable_legacy_abac = "true"
  resource_labels    = var.labels

  master_auth {
    username = "${var.master_username}"
    password = "${var.master_password}"

    client_certificate_config {
      issue_client_certificate = true
    }
  }

  network = "assareh-gke"

  node_config {
    machine_type = "${var.node_machine_type}"
    disk_size_gb = "${var.node_disk_size}"
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}
