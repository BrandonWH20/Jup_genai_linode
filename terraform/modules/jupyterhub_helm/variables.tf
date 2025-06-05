variable "kubeconfig_path" {
  description = "Path to kubeconfig for Helm provider"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to install JupyterHub into"
  type        = string
  default     = "jhub"
}

variable "chart_version" {
  description = "Version of the JupyterHub Helm chart"
  type        = string
  default     = "4.1.0"
}

variable "proxy_secret_token" {
  description = "Secret token for proxy auth"
  type        = string
  sensitive   = true
}

variable "admin_user" {
  description = "Admin username for dummy auth"
  type        = string
}

variable "storage_class" {
  description = "Storage class to use for persistent volumes"
  type        = string
  default     = "linode-block-storage"
}
variable "shared_rwx_storage_class" {
  description = "Storage class to use for shared RWX dataset volume"
  type        = string
  default     = "nfs-client"
}

variable "github_client_id" {
  type        = string
  sensitive   = true
}

variable "github_client_secret" {
  type        = string
  sensitive   = true
}
variable "subdomain" {
  type        = string
  description = "Subdomain used for JupyterHub"
}

variable "domain" {
  type        = string
  description = "Base domain used for JupyterHub"
}

