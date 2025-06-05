variable "namespace" {
  description = "The namespace in which to deploy the GPU Job Manager and related resources"
  type        = string
  default     = "jhub"
}

variable "shared_pvc_name" {
  description = "The name of the shared PersistentVolumeClaim used by all job-related pods"
  type        = string
  default     = "shared-dataset-pvc"
}
