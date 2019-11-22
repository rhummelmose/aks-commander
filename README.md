# AKS Commander
Using terraform, bash and optionally a CI/CD system like Azure DevOps to provision AKS clusters - blue/green style.

![Diagram](https://raw.githubusercontent.com/rhummelmose/aks-commander/master/resources/aks-commander-diagram.png)

## About
This repository seeks to provide an example implementation of how green/blue AKS cluster deployments can be done. The code base consists of 4 Terraform modules and some bash to simplify usage and provide additional functionality beyond infrastructure management.
## Usage
In the environment folder you'll find env and tfvars files that configure each environment. The env files provide base configuration for all modules, while module specific tfvars files can override configuration per module.
### Example
```console
➜ $ bash terraform.sh --environment=gbbcloudnative --action=apply --module=core
➜ $ bash terraform.sh --environment=gbbcloudnative --action=apply --module=rbac
➜ $ bash terraform.sh --environment=gbbcloudnative --action=apply --module=aks --workspace=blue
➜ $ bash bootstrap_cluster.sh gbbcloudnative blue
➜ $ bash terraform.sh --environment=gbbcloudnative --action=apply --module=tme --workspace=blue
➜ $ bash terraform.sh --environment=gbbcloudnative --action=apply --module=aks --workspace=green
➜ $ bash bootstrap_cluster.sh gbbcloudnative green
➜ $ bash terraform.sh --environment=gbbcloudnative --action=apply --module=tme --workspace=green
➜ $ echo "and round it goes.."
```
## Details
### Terraform
* core (core infrastructure that supports the cluster)
* rbac (aad identities and credentials required for aad enabled clusters)
* aks (the AKS cluster itself)
* tme (the Traffic Manager endpoint for an AKS cluster's ingress IP)
### Bash
* cluster_bootstrapper.sh (applies foundational objects on the cluster, installs ingress controller and ensures a public IP)
### Pre-requisites
The following has to be installed:
* Terraform >= 0.12.12
* helm3
* jq
* azure-cli (authenticated and with the aks-preview extension)
