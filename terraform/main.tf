resource "linode_lke_cluster" "lab_cluster" {
  label       = var.project_name
  k8s_version = var.k8s_version
  region      = var.region
  tags        = [var.institution, var.project_name]

  control_plane {
    high_availability = false # Enable for 99% uptime. Can always upgrade, cannot downgrade. Starts at $60/month
  }

  pool {
    type  = var.cpu_node_type
    count = var.cpu_node_count
  }
  lifecycle {
    ignore_changes = [
      pool,
    ]
  }
}

resource "linode_lke_node_pool" "gpu_pool" {
  cluster_id = linode_lke_cluster.lab_cluster.id
  type       = "g2-gpu-rtx4000a1-s"  # RTX 4000 with 16GB

  autoscaler {
    min = 1
    max = 3
  }

  labels = {
    pool = "${var.project_name}-gpu"
  }
}

module "namespace" {
  source = "./modules/namespace"
  namespace = var.namespace
}

module "jupyterhub" {
  source = "./modules/jupyterhub_helm"

  kubeconfig_path     = "${path.module}/kubeconfig.yaml"  # Adjust path as needed
  namespace           = var.namespace
  chart_version       = "4.1.0"
  proxy_secret_token  = "87a4bf51bd4462e47bcc518987c4c13c60b1cd6d41d80a5fb03cfc2192d5ee90"
  admin_user           = var.admin_user
  github_client_id     = var.github_client_id
  github_client_secret = var.github_client_secret
  subdomain           = var.subdomain
  domain              = var.domain
  storage_class       = "linode-block-storage"
  shared_rwx_storage_class   = "nfs-client"
 
  providers = {
     kubernetes = kubernetes
   }
 }          

module "https_automation" {
  source = "./modules/https_automation"

  domain           = var.domain           # e.g., "eloup.net"
  subdomain        = var.subdomain        # e.g., "jupyter"
  linode_token     = var.linode_token     
  kubeconfig_path  = "${path.module}/kubeconfig.yaml"
  namespace        = var.namespace
  email            = var.email            # for Let's Encrypt

  providers = {
	linode = linode
   }
}

module "gpu_job_queue" {
  source        = "./modules/gpu_job_queue"
}

module "nfs_rwx" {
  source                     = "./modules/nfs_rwx"
  namespace                  = var.namespace
  create_nfs_server          = true
  nfs_server_storage_size    = "100Gi"
  nfs_server_storage_class   = "linode-block-storage-retain"
  storage_class_name         = "nfs-client"
  kubeconfig_path            = var.kubeconfig_path
}

resource "null_resource" "label_gpu_nodes" {
  depends_on = [linode_lke_node_pool.gpu_pool]

  provisioner "local-exec" {
    command = <<EOT
      sleep 90
      for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
        if kubectl get node "$node" -o json | grep -q "g2"; then
          kubectl label node "$node" accelerator=nvidia --overwrite
        fi
      done
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "label_cpu_nodes" {
  depends_on = [linode_lke_cluster.lab_cluster]

  provisioner "local-exec" {
    command = <<EOT
      sleep 90
      for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
        if ! kubectl get node "$node" -o json | grep -q "g2"; then
          kubectl label node "$node" accelerator=none --overwrite
        fi
      done
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

