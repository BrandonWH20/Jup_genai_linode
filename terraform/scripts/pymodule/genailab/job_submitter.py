import os
import uuid
import json
import time
from datetime import datetime
from datasets import DatasetDict
from nbconvert import PythonExporter
import nbformat

def submit_gpu_job(trainer, dataset: DatasetDict, job_name, notebook_path="job.ipynb", base_dir="/shared"):
    job_id = str(uuid.uuid4())[:8]
    user = os.getenv("JUPYTERHUB_USER", "unknown")
    job_dir = os.path.join(base_dir, "jobs", "data", job_id)
    os.makedirs(job_dir, exist_ok=True)

    # 1. Save tokenized dataset
    dataset_path = os.path.join(job_dir, "dataset")
    dataset.save_to_disk(dataset_path)

    # 2. Save trainer arguments
    with open(os.path.join(job_dir, "trainer_args.json"), "w") as f:
        json.dump(trainer.args.to_dict(), f, indent=2)

    # 3. Convert notebook to .py and clean unsafe lines
    try:
        with open(notebook_path, "r", encoding="utf-8") as f:
            notebook = nbformat.read(f, as_version=4)
        py_script, _ = PythonExporter().from_notebook_node(notebook)

        cleaned_lines = []
        injected_subprocess = False

        for line in py_script.splitlines():
            if "get_ipython().system" in line:
                pip_cmd = line.split("get_ipython().system(")[-1].rstrip(")").strip("'\"")
                if not injected_subprocess:
                    cleaned_lines.append("import subprocess")
                    injected_subprocess = True
                cleaned_lines.append(f"subprocess.run({pip_cmd!r}, shell=True, check=True)")
                print("[INFO] Converted shell command:", pip_cmd)
                continue

            if any(x in line for x in ["submit_gpu_job(", "genailab", "import genailab", "from genailab"]):
                print("[INFO] Removed unsafe or interactive line:", line.strip())
                continue

            cleaned_lines.append(line)

        # 4. Append training + model save block
        final_block = f"""
# === Auto-Appended: Train & Save ===
trainer.train()

import os
from datetime import datetime

job_id = os.environ.get("JOB_ID", "{job_id}")
output_path = f"/shared/jobs/processed/{{job_id}}"
os.makedirs(output_path, exist_ok=True)

model.save_pretrained(output_path)
tokenizer.save_pretrained(output_path)

with open(os.path.join(output_path, "status.txt"), "w") as f:
    f.write(f"Training completed at {{datetime.utcnow().isoformat()}}\\n")

print(f"✅ Model saved to {{output_path}}")
"""
        cleaned_lines.append(final_block.strip())

        job_script_path = os.path.join(job_dir, "job.py")
        with open(job_script_path, "w") as f:
            f.write("\n".join(cleaned_lines))

    except Exception as e:
        print(f"[WARNING] Notebook conversion failed: {e}")
        return

    # 5. Verify job.py exists
    if not os.path.exists(job_script_path):
        print(f"[ERROR] job.py not found at {job_script_path}")
        return

    # 6. Save metadata
    metadata = {
        "job_id": job_id,
        "job_name": job_name,
        "submitted_by": user,
        "timestamp": datetime.utcnow().isoformat(),
        "notebook": os.path.basename(notebook_path),
    }
    with open(os.path.join(job_dir, "metadata.json"), "w") as f:
        json.dump(metadata, f, indent=2)

    # 7. Wait for sync
    time.sleep(0.5)

    # 8. Submit job to queue
    queue_entry = {
        "job_id": job_id,
        "job_name": job_name,
        "job_path": job_dir,
        "user": user,
        "image": "jupyter/scipy-notebook:latest",
        "command": f"JOB_ID={job_id} python /shared/jobs/data/{job_id}/job.py",
        "dataset": os.path.relpath(dataset_path, base_dir),
        "type": "gpu-training",
    }

    queue_path = os.path.join(base_dir, "jobs", "queue", f"{job_id}.json")
    os.makedirs(os.path.dirname(queue_path), exist_ok=True)
    with open(queue_path, "w") as f:
        json.dump(queue_entry, f, indent=2)

    print(f"\n  Job submitted: {job_name}")
    print(f"  ID: {job_id}")
    print(f"  Queue: {queue_path}")
    print(f"  Results: /shared/jobs/processed/{job_id}/")
