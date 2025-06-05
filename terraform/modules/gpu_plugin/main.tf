resource "kubernetes_manifest" "nvidia_device_plugin" {
  manifest = yamldecode(file("${path.module}/nvidia-device-plugin.yaml"))
}

module "gpu_plugin" {
  source          = "./gpu_plugin"
  kubeconfig_path = "${path.module}/kubeconfig.yaml"

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [
    linode_lke_node_pool.gpu_pool
  ]
}

