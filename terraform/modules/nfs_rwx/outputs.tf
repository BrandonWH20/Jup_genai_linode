output "nfs_server_dns" {
  description = "Internal DNS address of the NFS server"
  value       = "${var.nfs_service_name}.${var.nfs_server_namespace}.svc.cluster.local"
}

output "nfs_export_path" {
  description = "Exported path served by the NFS server"
  value       = "/exports"
}

output "nfs_storage_class" {
  description = "StorageClass created by the nfs-subdir-external-provisioner"
  value       = var.storage_class_name
}
output "nfs_ip_configmap_name" {
  value = data.kubernetes_config_map.nfs_ip.metadata[0].name
}
