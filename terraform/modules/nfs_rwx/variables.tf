variable "namespace" {
  description = "Namespace to deploy the nfs-subdir-external-provisioner"
  default     = "jhub"
}
variable "nfs_shared_size" {
  description = "Size of the shared RWX volume"
  default     = "90Gi"
}

variable "nfs_server_namespace" {
  description = "Namespace to deploy the internal NFS server"
  default     = "jhub"
}

variable "create_nfs_server" {
  description = "Whether to deploy the NFS server in-cluster"
  type        = bool
  default     = true
}

variable "nfs_server_name" {
  description = "Name of the NFS server pod"
  default     = "nfs-server"
}

variable "nfs_service_name" {
  description = "Name of the NFS headless service"
  default     = "nfs-service"
}

variable "nfs_server_storage_class" {
  description = "Storage class to use for the NFS server's backing volume"
  default     = "linode-block-storage"
}

variable "nfs_server_storage_size" {
  description = "Size of the PVC backing the NFS server"
  default     = "20Gi"
}

variable "storage_class_name" {
  description = "Name of the StorageClass to create with nfs-subdir-external-provisioner"
  default     = "nfs-client"
}
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
}
