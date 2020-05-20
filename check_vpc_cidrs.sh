#!/bin/bash

# Get previous vpc_cidrs
previous_vpc_cidr_blocks_b64=$(kubectl get configmaps -n kube-system aws-cni-cidrblocks -o json | jq -r '.data.cidrblocks')
if [[ $previous_vpc_cidr_blocks_b64 == "" ]]; then
    echo "No previous CIDR block found"
else
    previous_vpc_cidr_blocks=$(echo $previous_vpc_cidr_blocks_b64 | base64 -d)
    echo "Previous CIDR blocks:  $previous_vpc_cidr_blocks"
fi

# Get first interface of the machine
first_interface=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs | head -n 1)

# Get VPC CIDR block
vpc_cidr_blocks=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$first_interface/vpc-ipv4-cidr-blocks | tr "\n" ",")
echo "Found CIDR blocks: ${vpc_cidr_blocks}"

# Convert to base64
vpc_cidr_blocks_b64=$(echo $vpc_cidr_blocks | base64)

if [[ $previous_vpc_cidr_blocks_b64 == $vpc_cidr_blocks_b64 ]]; then
  echo "No action taken, CIDR blocks have not changed"
else
  echo "CIDRs in VPC changed, restarting AWS CNI nodes"
  # Delete all pods
  kubectl delete pods -l k8s-app=aws-node -n kube-system
  # Store new value in ConfigMap
  if [[ $? -eq 0 ]]; then
    echo "Pods deleted"
    kubectl create configmap -n kube-system aws-cni-cidrblocks --from-literal=cidrblocks="$vpc_cidr_blocks_b64" --dry-run=client -o yaml | kubectl apply -f -
  else
    echo "Pods were not deleted deleted"
  fi
fi
