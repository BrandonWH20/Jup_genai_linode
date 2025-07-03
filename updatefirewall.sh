#!/bin/bash

set -e

TAG="lke-genai"
NFS_PATH="/mnt/nfs-share"
EXPORTS_FILE="/etc/exports"
TMP_EXPORTS="/tmp/exports.new"

echo "Fetching LKE nodes and applying tag: $TAG..."

# Get all Linodes with 'lke' in the label
LKE_NODES=$(linode-cli linodes list --json | jq -c '.[] | select(.label | test("lke"))')

# Prepare exports file
echo -n > "$TMP_EXPORTS"

# Clear existing UFW rules for port 2049
ufw --force reset
ufw allow ssh

echo "$LKE_NODES" | while read -r NODE; do
  ID=$(echo "$NODE" | jq -r '.id')
  LABEL=$(echo "$NODE" | jq -r '.label')
  TAGS=$(echo "$NODE" | jq -r '.tags | join(",")')

  # Tag node if not already tagged
  if [[ "$TAGS" != *"$TAG"* ]]; then
    echo "Tagging $LABEL with $TAG..."
    linode-cli linodes update "$ID" --tags "$TAGS,$TAG"
  fi

  # Get private IPs only
  echo "$NODE" | jq -r '.ipv4[] | select(startswith("192."))' | while read -r IP; do
    echo "Allowing IP: $IP"
    echo "$NFS_PATH $IP(rw,sync,no_subtree_check,no_root_squash)" >> "$TMP_EXPORTS"
    ufw allow from "$IP" to any port 2049 proto tcp
  done
done

echo "Updating /etc/exports..."
mv "$TMP_EXPORTS" "$EXPORTS_FILE"
exportfs -ra
ufw enable

echo "NFS access synced successfully."

