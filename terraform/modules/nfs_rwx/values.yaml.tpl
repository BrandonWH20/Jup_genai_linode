nfs:
  server: "${nfs_server}"
  path: "${nfs_path}"

storageClass:
  name: "${storage_class_name}"
  defaultClass: true
  reclaimPolicy: Retain
  accessModes: ["ReadWriteMany"]
  volumeBindingMode: Immediate
  mountOptions:
    - vers=4.1
    - nolock

