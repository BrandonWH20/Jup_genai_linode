terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "helm_release" "jupyterhub" {
  name       = "jhub"
  chart      = "jupyterhub"
  namespace  = var.namespace
  repository = "https://jupyterhub.github.io/helm-chart"
  version    = var.chart_version

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml.tmpl", {
	  proxy_secret_token = var.proxy_secret_token
	  admin_user          = var.admin_user
	  storage_class       = var.storage_class
  	  github_client_id    = var.github_client_id
   	  github_client_secret = var.github_client_secret
	  subdomain 	      = var.subdomain
          domain             = var.domain
          storage_class       = var.storage_class
	})

  ]
}

