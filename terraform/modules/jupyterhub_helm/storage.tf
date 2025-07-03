# resource "kubernetes_persistent_volume" "shared_nfs" {
#   metadata {
#     name = "shared-nfs-pv"
#   }

#   spec {
#     capacity = {
#       storage = "95Gi"
#     }
#     access_modes = ["ReadWriteMany"]
#     persistent_volume_reclaim_policy = "Retain"

#     persistent_volume_source {
#       nfs {
#         server = "192.168.131.76"  # private IP of Linode NFS host
#         path   = "/mnt/nfs-share"
#       }
#     }

#     mount_options = [
#       "vers=4.1",
#       "noatime"
#     ]
#   }
# }

# resource "kubernetes_persistent_volume_claim" "shared_nfs" {
#   metadata {
#     name      = "shared-nfs"
#     namespace = var.namespace
#   }

#   spec {
#     access_modes = ["ReadWriteMany"]

#     resources {
#       requests = {
#         storage = "95Gi"
#       }
#     }

#     volume_name = kubernetes_persistent_volume.shared_nfs.metadata[0].name
#   }
# }

