variable "namespace" {
  description = "Namespace to deploy the job into"
  type        = string
  default     = "jhub"
}

variable "host_path" {
  description = "Path to the shared dataset on the host"
  type        = string
}

