

variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}
variable "kubeconfig_path" {
  description = "Path to kubeconfig file used to connect to Kubernetes cluster"
  type        = string
  default     = "./kubeconfig.yaml"
}

variable "institution" {
  description = "The name of the institution (used in resource tags)"
  type        = string
  default     = "test-genai-akamai" #CHANGE_ME
}

variable "project_name" {
  description = "The project name or cluster label"
  type        = string
  default     = "genai-lab" #CHANGE_ME
}

variable "region" {
  description = "The Linode region to deploy the cluster in"
  type        = string
  default     = "us-sea" # Examples: us-iad (DC), us-ord (Chicago) #CHANGE_ME
}

variable "cpu_node_type" {
  description = "The type of Linode instance used for the CPU node pool"
  type        = string
  default     = "g6-standard-4" # Use 'linode-cli linodes types' to explore more #MAYBE_CHANGE_MAYBE_DONT
}

variable "cpu_node_count" {
  description = "The number of nodes in the CPU node pool"
  type        = number
  default     = 3 #Three is a good number to start - Brandon H 
}
variable "gpu_node_count" {
  description = "Number of GPU nodes in the pool (can scale 1–3)"
  type        = number
  default     = 1
}

variable "storage_class" {
  description = "Storage class to use for persistent volumes"
  type        = string
  default     = "linode-block-storage"
}

variable "shared_rwx_storage_class" {
  description = "Storage class to use for shared RWX volumes"
  type        = string
  default     = "nfs-client"
}


variable "k8s_version" {
  description = "The Kubernetes version to deploy on Linode LKE"
  type        = string
  default     = "1.32" # Valid options as of early 2025: 1.31, 1.32
}

### DOMAIN SETTINGS ###

variable "domain" {
  description = "The base DNS domain (must be managed by Linode)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for JupyterHub HTTPS (e.g., 'jupyter')"
  type        = string
}

variable "email" {
  description = "Email address to use with Let's Encrypt for TLS certs"
  type        = string
}
variable "admin_user" {
  type        = string
  description = "GitHub username for JupyterHub admin"
}

variable "github_client_id" {
  type        = string
  sensitive   = true
  description = "GitHub OAuth Client ID"
}

variable "github_client_secret" {
  type        = string
  sensitive   = true
  description = "GitHub OAuth Client Secret"
}
variable "namespace" {
  description = "The Kubernetes namespace used across modules"
  type        = string
}

