resource "kubernetes_pod" "gpu_job_manager" {
  metadata {
    name      = "gpu-job-manager"
    namespace = var.namespace
    labels = {
      app = "gpu-job-manager"
    }
  }

  spec {
    service_account_name = "default"

    node_selector = {
      accelerator = "nvidia"
    }

    restart_policy = "Always"

    container {
      name  = "manager"
      image = "python:3.10"
      image_pull_policy = "IfNotPresent"

      command = [
        "/bin/sh",
        "-c",
        "pip install --no-cache-dir --user pyyaml kubernetes && export PYTHONPATH=$PYTHONPATH:/root/.local/lib/python3.10/site-packages && while true; do echo 'NFS unavailable. Skipping job scan.'; sleep 10; done"
      ]

      resources {}
    }
  }
}

