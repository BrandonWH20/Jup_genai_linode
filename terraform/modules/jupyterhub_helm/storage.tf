resource "kubernetes_persistent_volume_claim" "shared_dataset" {
  metadata {
    name      = "shared-dataset-pvc"
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.shared_rwx_storage_class

    resources {
      requests = {
        storage = "90Gi"
      }
    }
  }
}


