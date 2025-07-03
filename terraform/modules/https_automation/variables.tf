variable "domain" {
  description = "The root DNS domain managed in Linode"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for JupyterHub (e.g., 'jupyter')"
  type        = string
}

variable "linode_token" {
  description = "Linode API token for DNS + NodeBalancer control"
  type        = string
  sensitive   = true
}

variable "namespace" {
  description = "Namespace where JupyterHub and Ingress will be deployed"
  type        = string
  default     = "jhub"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
}

variable "email" {
  description = "Email for Let's Encrypt registration"
  type        = string
}


