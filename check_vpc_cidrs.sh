#!/bin/bash

# Get previous vpc_cidrs
previous_vpc_cidr_blocks_b64=$(kubectl get configmaps -n kube-system aws-cni-cidrblocks -o template --template={{.data.cidrblocks}} || echo "empty")
if [[ $previous_vpc_cidr_blocks_b64 == "empty" ]]; then
    echo "No previous CIDR block found"
else
    previous_vpc_cidr_blocks=$(echo $previous_vpc_cidr_blocks_b64 | base64 -d)
    echo "Previous CIDR blocks:  $previous_vpc_cidr_blocks"
fi

# Get first interface of the machine
first_interface=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs | head -n 1)

# Get VPC CIDR block
vpc_cidr_blocks=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$first_interface/vpc-ipv4-cidr-blocks | tr "\n" " ")
echo "Found CIDR blocks: ${vpc_cidr_blocks}"

# Convert to base64
vpc_cidr_blocks_b64=$(echo $vpc_cidr_blocks | base64)

if [[ $previous_vpc_cidr_blocks_b64 == $vpc_cidr_blocks_b64 ]]; then
  echo "No action taken, CIDR blocks have not changed"
else
  echo "CIDRs in VPC changed, restarting AWS CNI nodes"
  # Rollout aws-node daemonset
  kubectl rollout restart daemonset aws-node -n kube-system
  # Store new value in ConfigMap
  kubectl create configmap -n kube-system aws-cni-cidrblocks --from-literal=cidrblocks=$vpc_cidr_blocks_b64 --dry-run=client -o yaml | kubectl apply -f -
fi