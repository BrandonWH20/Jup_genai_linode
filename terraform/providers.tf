
# Declares Linode as the required provider and sets it up using your API token.

terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.37.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }
}

provider "linode" {
  token = var.linode_token
}
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

