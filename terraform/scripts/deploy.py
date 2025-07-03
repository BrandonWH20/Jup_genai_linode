#!/usr/bin/env python3

import subprocess
import time
import os

def run(cmd, cwd=None, check=True):
    print(f"Running: {' '.join(cmd)}")
    try:
        subprocess.run(cmd, cwd=cwd, check=check)
    except subprocess.CalledProcessError as e:
        print(f"Command failed: {' '.join(cmd)}")
        if check:
            raise e

def tf(target=None):
    cmd = ["terraform", "apply", "-auto-approve"]
    if target:
        cmd += ["-target", target]
    run(cmd)

def export_kubeconfig():
    print("Exporting kubeconfig.yaml")
    try:
        with open("kubeconfig.yaml", "w") as f:
            subprocess.run(["terraform", "output", "-raw", "kubeconfig_yaml"], stdout=f, check=True)
        os.environ["KUBECONFIG"] = os.path.abspath("kubeconfig.yaml")
    except subprocess.CalledProcessError:
        print("Failed to export kubeconfig — ensure LKE cluster has finished creating")

def wait_for_kubectl():
    print("Waiting for kubectl to be ready...")
    for i in range(30):
        if subprocess.run(["kubectl", "get", "nodes"], stdout=subprocess.DEVNULL).returncode == 0:
            print("kubectl is ready")
            return
        print(f"Attempt {i+1}/30: waiting 5 seconds")
        time.sleep(5)
    raise Exception("kubectl not ready in time")

def apply_cert_manager_crds():
    print("Applying cert-manager CRDs")
    run([
        "kubectl", "apply", "-f",
        "https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml"
    ])

def wait_for_crd(name):
    print(f"Waiting for CRD {name}...")
    for _ in range(30):
        if subprocess.run(["kubectl", "get", "crd", name], stdout=subprocess.DEVNULL).returncode == 0:
            print(f"CRD {name} is ready")
            return
        time.sleep(5)
    raise Exception(f"Timeout waiting for CRD: {name}")

def wait_for_lb_ip(service, namespace="ingress-nginx"):
    print(f"Waiting for LoadBalancer IP on {service}.{namespace}...")
    for _ in range(30):
        result = subprocess.run(
            ["kubectl", "get", "svc", service, "-n", namespace,
             "-o", "jsonpath={.status.loadBalancer.ingress[0].ip}"],
            capture_output=True, text=True
        )
        ip = result.stdout.strip()
        if ip:
            print(f"LoadBalancer IP: {ip}")
            return ip
        time.sleep(10)
    raise Exception("LoadBalancer IP not ready")

def main():
    print("Starting Terraform-based cluster setup")
    try:
        tf("linode_lke_cluster.lab_cluster")
        export_kubeconfig()
        wait_for_kubectl()
    except Exception as e:
        print(f"Early setup failed: {e}")
        return

    try:
        tf("module.namespace")
        tf("module.jupyterhub")
    except Exception as e:
        print(f"JupyterHub setup failed: {e}")

    try:
        tf("module.https_automation.helm_release.cert_manager")
        apply_cert_manager_crds()
        wait_for_crd("clusterissuers.cert-manager.io")
        tf("module.https_automation.kubernetes_manifest.cluster_issuer")
        tf("module.https_automation.helm_release.ingress_nginx")
        wait_for_lb_ip("ingress-nginx-controller")
        tf("module.https_automation.linode_domain_record.jupyterhub_a_record")
        tf("module.https_automation.kubernetes_manifest.jupyterhub_ingress")
    except Exception as e:
        print(f"HTTPS automation setup failed: {e}")

    try:
        tf("module.gpu_job_queue")
        tf("module.gpu_plugin")
        tf("module.permissions_fixer")
        tf("module.nfs_rwx")  # Absolutely last
    except Exception as e:
        print(f"Final setup phase failed: {e}")

    print("Deployment process finished. You can rerun this script to resume if any parts failed.")

if __name__ == "__main__":
    main()
