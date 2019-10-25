# AKS Commander
Using terraform, bash and optionally a CI/CD system like Azure DevOps to provision AKS clusters - blue/green style.
## About
This repository seeks to provide an example implementation of how green/blue AKS cluster deployments can be done. The code base consists of 4 Terraform modules and some bash to simplify usage and provide additional functionality beyond infrastructure management.
### Terraform
* core (core infrastructure that supports the cluster)
* rbac (aad identities and credentials required for aad enabled clusters)
* aks (the AKS cluster itself)
* tme (the Traffic Manager endpoint for an AKS cluster's ingress IP)
### Bash
* cluster_bootstrapper.sh (applies foundational objects on the cluster, installs ingress controller and ensures a public IP)
## Prerequisites
The following has to be installed:
* Terraform >= 0.12.12
* helm3
* jq
* azure-cli (authenticated and with the aks-preview extension)
## Usage
In the root folder you'll find the env and tfvars files that you'll have to edit before you start playing. The two env files have to be edited and they will serve as the base configuration for all modules, while the individual module specific tfvars files can be used to override configuration.
In addition you'll have to set the secret for the service principal you want to use for the Terraform backend (a collection in an Azure blob) in the environment with the variable: *AKSCOMM_TF_BACKEND_CLIENT_SECRET*
### Steps
1. bash terraform.sh --action=apply --module=core
1. bash terraform.sh --action=apply --module=rbac
1. bash terraform.sh --action=apply --module=aks --workspace=green
1. bash bootstrap_cluster.sh green
1. bash terraform.sh --action=apply --module=tme --workspace=green
1. bash terraform.sh --action=apply --module=aks --workspace=blue
1. bash bootstrap_cluster.sh blue
1. bash terraform.sh --action=apply --module=tme --workspace=blue
1. bash terraform.sh --action=destroy --module=tme --workspace=green
1. bash terraform.sh --action=destroy --module=aks --workspace=green
1. and round it goes..
## Diagram
Coming soon :)
