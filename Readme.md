# AWS CNI Restarter

This Kubernetes CronJob has been developed to restart the AWS CNI pods when a new VPC CIDR has been added to the VPC.

Currently IpamD only checks for VPC CIDRs on initial boot and does not reconcile additional CIDRs added afterwards.

This cronjob will be executed every 5 minutes an discovers the Additional VPC CIDRs using the AWS metadata endpoint.

Results from one execution are stored in a configmap to check on next execution.