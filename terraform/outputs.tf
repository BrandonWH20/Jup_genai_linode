output "kubeconfig_yaml" {
  description = "Decoded kubeconfig YAML for use with kubectl"
  value       = base64decode(linode_lke_cluster.lab_cluster.kubeconfig)
  sensitive   = true
}
output "dashboard_url" {
  description = "Web dashboard URL (if enabled)"
  value       = linode_lke_cluster.lab_cluster.dashboard_url
}

output "region" {
  description = "Region where the cluster is deployed"
  value       = linode_lke_cluster.lab_cluster.region
}
