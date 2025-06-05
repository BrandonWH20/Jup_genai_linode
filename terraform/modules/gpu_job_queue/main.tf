resource "kubernetes_service_account" "gpu_job_submitter" {
  metadata {
    name      = "gpu-job-submitter"
    namespace = var.namespace
  }
}

resource "kubernetes_role" "gpu_job_creator" {
  metadata {
    name      = "gpu-job-creator"
    namespace = var.namespace
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["create", "get", "list", "watch", "delete"]
  }
}

resource "kubernetes_role_binding" "gpu_job_submitter_binding" {
  metadata {
    name      = "gpu-job-binding"
    namespace = var.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.gpu_job_creator.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.gpu_job_submitter.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_pod" "gpu_job_manager" {
  metadata {
    name      = "gpu-job-manager"
    namespace = var.namespace
    labels = {
      app = "gpu-job-manager"
    }
  }

  spec {
    service_account_name = kubernetes_service_account.gpu_job_submitter.metadata[0].name
    restart_policy       = "Always"

    node_selector = {
      accelerator = "nvidia"
    }

    container {
      name  = "manager"
      image = "python:3.10"
      command = [
  "/bin/sh",
  "-c",
  "pip install --no-cache-dir --user pyyaml kubernetes && export PYTHONPATH=$PYTHONPATH:/root/.local/lib/python3.10/site-packages && while true; do python /shared/genailab/gpu_job_manager.py; sleep 10; done"
]


      volume_mount {
        name       = "shared"
        mount_path = "/shared"
      }
    }

    volume {
      name = "shared"
      persistent_volume_claim {
        claim_name = var.shared_pvc_name
      }
    }
  }
}
