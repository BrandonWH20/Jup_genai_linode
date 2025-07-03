import os
import json
import time
import uuid
import threading
import traceback
from kubernetes import client, config

QUEUE_DIR = "/shared/jobs/queue"
ARCHIVE_DIR = "/shared/jobs/queue/submitted"

def load_job_spec(filepath):
    with open(filepath, "r") as f:
        return json.load(f)

def submit_k8s_job(job_data, job_uuid):
    batch_v1 = client.BatchV1Api()

    # Kubernetes job name must be RFC1123 compliant
    raw_name = job_data.get("job_name", f"job-{job_uuid}")
    safe_name = raw_name.lower().replace("_", "-")
    job_name = f"{safe_name}-{job_uuid}"

    image = job_data.get("image", "jupyter/scipy-notebook:latest")
    command = job_data.get("command", "echo Hello from GPU job")
    gpu_count = job_data.get("gpu", 1)

    # Prometheus-compatible labels (alphanumeric + '-', '_', '.')
    def safe_label(value):
        return str(value).lower().replace("/", "-").replace("_", "-")

    prometheus_labels = {
        "job-type": safe_label(job_data.get("type", "gpu-task")),
        "job-id": job_uuid,
        "submitted-by": safe_label(job_data.get("user", "unknown")),
        "dataset": safe_label(job_data.get("dataset", "unspecified")),
    }

    job = client.V1Job(
        metadata=client.V1ObjectMeta(
            name=job_name,
            namespace="jhub",
            labels=prometheus_labels,
        ),
        spec=client.V1JobSpec(
            template=client.V1PodTemplateSpec(
                metadata=client.V1ObjectMeta(labels=prometheus_labels),
                spec=client.V1PodSpec(
                    restart_policy="Never",
                    containers=[
                        client.V1Container(
                            name="trainer",
                            image=image,
                            command=["/bin/sh", "-c", command],
                            volume_mounts=[
                                client.V1VolumeMount(
                                    name="shared", mount_path="/shared"
                                )
                            ],
                            resources=client.V1ResourceRequirements(
                                limits={"nvidia.com/gpu": str(gpu_count)}
                            ),
                        )
                    ],
                    volumes=[
                        client.V1Volume(
                            name="shared",
                            persistent_volume_claim=client.V1PersistentVolumeClaimVolumeSource(
                                claim_name="shared-dataset-pvc"
                            )
                        )
                    ],
                    node_selector={"accelerator": "nvidia"},
                ),
            ),
            backoff_limit=1,
        ),
    )

    print(f"🚀 Submitting job: {job_name}")
    batch_v1.create_namespaced_job(namespace="jhub", body=job)

def ensure_dirs():
    os.makedirs(QUEUE_DIR, exist_ok=True)
    os.makedirs(ARCHIVE_DIR, exist_ok=True)

def monitor_and_cleanup_jobs():
    batch_v1 = client.BatchV1Api()
    seen = set()

    while True:
        try:
            jobs = batch_v1.list_namespaced_job(
                namespace="jhub",
                label_selector="job-type=gpu-training"
            )

            for job in jobs.items:
                name = job.metadata.name
                status = job.status

                if name in seen:
                    continue

                if status.succeeded == 1:
                    print(f"[✅] Job {name} succeeded. Cleaning up in 30s...")
                    seen.add(name)
                    threading.Thread(target=delayed_delete_job, args=(name,), daemon=True).start()

                elif status.failed and status.failed >= 1:
                    print(f"[⚠️] Job {name} failed.")
                    seen.add(name)

        except Exception as e:
            print(f"[ERROR] Cleanup monitor failed: {e}")
            traceback.print_exc()

        time.sleep(15)

def delayed_delete_job(name):
    time.sleep(30)
    try:
        batch_v1 = client.BatchV1Api()
        batch_v1.delete_namespaced_job(
            name=name,
            namespace="jhub",
            body=client.V1DeleteOptions(propagation_policy='Background')
        )
        print(f"[🧼] Deleted completed job: {name}")
    except Exception as e:
        print(f"[ERROR] Failed to delete job {name}: {e}")
        traceback.print_exc()

def submission_loop():
    while True:
        try:
            files = [f for f in os.listdir(QUEUE_DIR) if f.endswith(".json")]
            for fname in files:
                path = os.path.join(QUEUE_DIR, fname)
                try:
                    job_data = load_job_spec(path)
                    job_uuid = str(uuid.uuid4())[:8]
                    submit_k8s_job(job_data, job_uuid)

                    new_fname = f"{os.path.splitext(fname)[0]}-{job_uuid}.submitted"
                    os.rename(path, os.path.join(ARCHIVE_DIR, new_fname))
                except Exception as e:
                    print(f"[ERROR] Failed to submit {fname}: {e}")
                    traceback.print_exc()
        except Exception as e:
            print(f"[FATAL] Submission loop error: {e}")
            traceback.print_exc()

        time.sleep(10)

if __name__ == "__main__":
    config.load_incluster_config()
    ensure_dirs()

    threading.Thread(target=submission_loop, daemon=True).start()
    monitor_and_cleanup_jobs()
