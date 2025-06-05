terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

# ─────────────────────────────────────────────────────────────
# Persistent Volume for NFS server
# ─────────────────────────────────────────────────────────────

resource "kubernetes_persistent_volume" "nfs_shared" {
  metadata {
    name = "shared-dataset-pv"
  }

  spec {
    capacity = {
      storage = "90Gi"
    }

    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = var.storage_class_name
    volume_mode                      = "Filesystem"

    persistent_volume_source {
      nfs {
        path   = "/exports"
        server = "nfs-service.jhub.svc.cluster.local"
      }
    }
  }

}


resource "kubernetes_persistent_volume_claim" "nfs_shared" {
  metadata {
    name      = "shared-dataset-pvc"
    namespace = var.namespace
  }

  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = var.storage_class_name

    resources {
      requests = {
        storage = var.nfs_shared_size
      }
    }
  }
}


resource "kubernetes_persistent_volume_claim" "nfs_data" {
  count = var.create_nfs_server ? 1 : 0

  metadata {
    name      = "nfs-data-rwo"
    namespace = "jhub"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.nfs_server_storage_size
      }
    }

    storage_class_name = var.nfs_server_storage_class
  }
}

# ─────────────────────────────────────────────────────────────
# NFS Server Pod + Service
# ─────────────────────────────────────────────────────────────

resource "kubernetes_pod" "nfs_server" {
  count = var.create_nfs_server ? 1 : 0

  metadata {
    name      = "nfs-server"
    namespace = "jhub"
    labels = {
      app = "nfs-server"
    }
  }

  spec {
    security_context {
      run_as_user = 0
      fs_group    = 0
    }

    container {
      name  = "nfs"
      image = "erichough/nfs-server"

      port {
        container_port = 2049
        name           = "nfs"
      }

      security_context {
        privileged = true
      }

      env {
        name  = "NFS_EXPORT_0"
        value = "/exports *(rw,sync,no_subtree_check,no_root_squash)"
      }

      volume_mount {
        name       = "nfs-data"
        mount_path = "/exports"
      }
    }

    volume {
      name = "nfs-data"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.nfs_data[0].metadata[0].name
      }
    }
  }
}

resource "kubernetes_service" "nfs" {
  count = var.create_nfs_server ? 1 : 0

  metadata {
    name      = "nfs-service"
    namespace = "jhub"
  }

  spec {
    cluster_ip = "None"

    selector = {
      app = "nfs-server"
    }

    port {
      name        = "nfs"
      port        = 2049
      target_port = 2049
    }
  }
}

# ─────────────────────────────────────────────────────────────
# Wait for Pod Readiness
# ─────────────────────────────────────────────────────────────

resource "null_resource" "wait_for_nfs_server_ready" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for NFS server pod to be ready..."
      for i in {1..30}; do
        if kubectl get pod nfs-server -n jhub -o jsonpath='{.status.phase}' | grep -q "Running"; then
          echo "NFS server is running."
          exit 0
        fi
        sleep 5
      done
      echo "Timeout waiting for NFS server pod."
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [kubernetes_pod.nfs_server]
}

# ─────────────────────────────────────────────────────────────
# Apply Job to Publish Pod IP into ConfigMap
# ─────────────────────────────────────────────────────────────


# ─────────────────────────────────────────────────────────────
# Fetch ConfigMap containing Pod IP
# ─────────────────────────────────────────────────────────────

data "kubernetes_config_map" "nfs_ip" {
  metadata {
    name      = "nfs-ip-nfs-server"
    namespace = "jhub"
  }
 }

# ─────────────────────────────────────────────────────────────
# Render Helm values for RWX provisioner using IP
# ─────────────────────────────────────────────────────────────

locals {
  rendered_values = templatefile("${path.module}/values.yaml.tpl", {
    nfs_server         = "nfs-service.jhub.svc.cluster.local"
    nfs_path           = "/exports"
    storage_class_name = var.storage_class_name
  })
}

resource "helm_release" "nfs_provisioner" {
  name       = "nfs-subdir"
  namespace  = "jhub"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
  chart      = "nfs-subdir-external-provisioner"
  version    = "4.0.18"
  wait       = false
  timeout    = 600

  values = [local.rendered_values]

  depends_on = [kubernetes_service.nfs]
}

