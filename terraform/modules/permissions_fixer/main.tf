resource "kubernetes_job" "fix_shared_dataset_permissions" {
  metadata {
    name      = "fix-shared-dataset"
    namespace = var.namespace
  }

  spec {
    template {
      metadata {
        labels = {
          job = "fix-shared-dataset"
        }
      }

      spec {
        restart_policy = "Never"

        node_selector = {
          accelerator = "none"
        }

        container {
          name  = "fix-perms"
          image = "alpine:3.18"

          command = ["/bin/sh", "-c"]
          args    = [
            "chown -R 1000:100 /mnt/shared-dataset && chmod -R 775 /mnt/shared-dataset"
          ]

          volume_mount {
            mount_path = "/mnt/shared-dataset"
            name       = "shared-dataset"
          }
        }

        volume {
          name = "shared-dataset"

          host_path {
            path = var.host_path
            type = "Directory"
          }
        }
      }
    }

    backoff_limit = 1
  }
}

