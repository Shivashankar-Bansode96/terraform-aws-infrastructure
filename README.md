# Terraform AWS Infrastructure

Reusable Infrastructure as Code for deploying consistent AWS infrastructure across multiple environments using Terraform and GitHub Actions.

## Overview

This project demonstrates how to build and manage AWS infrastructure using reusable Terraform modules and an automated CI/CD pipeline.

The same Terraform modules are used across three isolated environments:

- Development
- Staging
- Production

Each environment has its own Terraform state stored remotely in Amazon S3.

Deployments are automated through GitHub Actions using AWS OIDC authentication, eliminating the need to store long-lived AWS access keys in GitHub.

---

## Architecture

```text
                         GitHub
                            |
                            |
                    GitHub Actions
                            |
                       OIDC / JWT
                            |
                            v
                  AWS IAM Role
             GitHubActions-Terraform
                            |
                            v
                       Terraform
                            |
          +-----------------+-----------------+
          |                 |                 |
          v                 v                 v
        DEV             STAGING             PROD
          |                 |                 |
       VPC + EC2         VPC + EC2         VPC + EC2
          |                 |                 |
          +-----------------+-----------------+
                            |
                            v
                    Amazon S3 Backend
                     Remote Terraform
                          State


AWS environment architecture

Each environment contains:

VPC
|
+-- Internet Gateway
|
+-- Public Subnet
|      |
|      +-- EC2 Web Server
|             |
|             +-- Security Group
|
+-- Public Route Table
       |
       +-- Internet Gateway

Technology Stack
Technology	Purpose -Terraform	Infrastructure as Code
AWS	- Cloud infrastructure
Amazon VPC	- Network isolation
Amazon EC2	- Web server
Amazon S3	- Remote Terraform state
AWS IAM	- Access control
AWS OIDC -	Keyless GitHub authentication
GitHub Actions -	CI/CD automation
Amazon Linux 2023	EC2 - operating system
Nginx	 - Web server

Project Structure

terraform-aws-infrastructure/
|
+-- .github/
|   |
|   +-- workflows/
|       |
|       +-- terraform.yml
|
+-- bootstrap/
|   |
|   +-- main.tf
|   +-- variables.tf
|   +-- outputs.tf
|   +-- terraform.tfvars
|
+-- environments/
|   |
|   +-- dev/
|   |   +-- main.tf
|   |   +-- variables.tf
|   |   +-- outputs.tf
|   |   +-- terraform.tfvars
|   |
|   +-- staging/
|   |   +-- main.tf
|   |   +-- variables.tf
|   |   +-- outputs.tf
|   |   +-- terraform.tfvars
|   |
|   +-- prod/
|       +-- main.tf
|       +-- variables.tf
|       +-- outputs.tf
|       +-- terraform.tfvars
|
+-- modules/
|   |
|   +-- vpc/
|   |   +-- main.tf
|   |   +-- variables.tf
|   |   +-- outputs.tf
|   |
|   +-- security-group/
|   |   +-- main.tf
|   |   +-- variables.tf
|   |   +-- outputs.tf
|   |
|   +-- ec2/
|       +-- main.tf
|       +-- variables.tf
|       +-- outputs.tf
|
+-- provider.tf
+-- version.tf
+-- .gitignore
+-- README.md

Terraform Modules

The project uses reusable Terraform modules rather than duplicating infrastructure definitions for every environment.

VPC Module

Location:

modules/vpc/

Creates:

VPC
Internet Gateway
Public subnet
Public route table
Route table association

The module receives environment-specific values such as:

VPC CIDR
Public subnet CIDR
Availability Zone
Environment name

Security Group Module

Location:

modules/security-group/

Creates the security group used by the web server.

Current rules:

Inbound:
HTTP / TCP / 80 / 0.0.0.0/0

Outbound:
All traffic

The security group is associated with the environment's VPC.

EC2 Module

Location:

modules/ec2/

Creates the web server EC2 instance.

The module:

Retrieves the latest Amazon Linux 2023 AMI through AWS Systems Manager Parameter Store
Creates an EC2 instance
Assigns it to the public subnet
Associates the environment security group
Assigns a public IP
Installs Nginx through user data
Creates a simple environment-specific web page

Example:

Hello from Terraform!

Environment: dev

Infrastructure managed with Terraform.

Environments

The project contains three independent Terraform environments.

Development
VPC CIDR:
10.0.0.0/16

Public Subnet:
10.0.1.0/24

Instance:
t3.micro

Terraform state:

dev/terraform.tfstate

Staging
VPC CIDR:
10.1.0.0/16

Public Subnet:
10.1.1.0/24

Instance:
t3.micro

Terraform state:

staging/terraform.tfstate

Production
VPC CIDR:
10.2.0.0/16

Public Subnet:
10.2.1.0/24

Instance:
t3.small

Terraform state:

prod/terraform.tfstate

Production uses a larger EC2 instance type to demonstrate environment-specific configuration.

Remote Terraform State

Terraform state is stored remotely in Amazon S3.

Backend bucket:

terraform-aws-infrastructure-shiv-2026

Each environment has an independent state key:

dev/terraform.tfstate
staging/terraform.tfstate
prod/terraform.tfstate

The S3 backend uses native Terraform state locking:

use_lockfile = true

This prevents concurrent Terraform operations from modifying the same state simultaneously.

Terraform state files are excluded from Git through .gitignore.

Bootstrap

The bootstrap/ directory creates the S3 bucket used for Terraform remote state.

The bucket is configured with:

S3 versioning
Server-side encryption
Public access blocking
Terraform management tags

Bootstrap is intentionally separated from the environment infrastructure because the remote-state backend must exist before the environment configurations can use it.

CI/CD Pipeline

The project uses GitHub Actions to automatically validate, plan, and deploy Terraform changes.

                         Git Push
                            |
                            v
                  +-------------------+
                  | Terraform Check   |
                  +-------------------+
                            |
                            v
                  +-------------------+
                  | Terraform Plan    |
                  +-------------------+
                     |      |      |
                     v      v      v
                   Dev   Staging   Prod
                  Plans   Plans    Plans
                     \      |      /
                      \     |     /
                       v    v    v
                    Plan Artifacts
                            |
                            v
                       Dev Apply
                            |
                            v
                    Staging Approval
                            |
                            v
                    Staging Apply
                            |
                            v
                      Prod Approval
                            |
                            v
                       Prod Apply

Terraform Check

Every push and pull request targeting main runs Terraform validation.

The pipeline checks:

terraform fmt -check -recursive

and validates each environment:

terraform init -backend=false
terraform validate

This catches formatting and configuration errors before infrastructure changes are deployed.

Terraform Plan

For pushes to main, Terraform creates plans for:

Dev
Staging
Production

Each plan is saved as:

tfplan

and uploaded as a GitHub Actions artifact.

The artifact is retained temporarily for deployment.

Exact Plan Deployment

The pipeline does not generate a new plan during the apply stage.

Instead:

terraform plan
      |
      v
   tfplan
      |
      v
GitHub Actions Artifact
      |
      v
Download Artifact
      |
      v
terraform apply tfplan

This ensures that the plan produced during the planning stage is the plan that gets applied.

Environment Approvals

GitHub Environments are used to control deployment promotion.

Configured environments:

dev
staging
prod

Development can deploy automatically.

Staging requires an approval before deployment.

Production requires an approval before deployment.

This creates a controlled promotion model:

Dev
 |
 v
Staging
 |
 v
Production

AWS OIDC Authentication

GitHub Actions authenticates to AWS using OpenID Connect.

The workflow does not store long-lived AWS access keys.

The authentication flow is:

GitHub Actions
      |
      | OIDC token
      v
GitHub OIDC Provider
      |
      v
AWS IAM Trust Policy
      |
      v
GitHubActions-Terraform
      |
      v
AWS APIs

The IAM trust relationship restricts access to the intended GitHub repository and approved GitHub Actions subjects.

The workflow uses:

permissions:
  id-token: write
  contents: read

The id-token: write permission allows GitHub Actions to request an OIDC token.

It does not itself grant AWS permissions.

IAM Security

The GitHub Actions IAM role does not use AdministratorAccess.

Instead, it uses a custom least-privilege policy designed around the infrastructure managed by this project.

The permissions cover the required:

VPC operations
Subnet operations
Route table operations
Internet Gateway operations
Security Group operations
EC2 operations
Amazon Linux AMI parameter lookup
Terraform S3 state access

This follows the principle of least privilege.

Terraform Version

The project requires:

Terraform >= 1.6.0

The AWS provider uses:

~> 6.0

Local Usage
Prerequisites

Install:

Terraform
AWS CLI
Git
An AWS account

Configure AWS credentials locally using the AWS CLI.

Verify authentication:

aws sts get-caller-identity


Security Considerations

This project demonstrates several security practices:

GitHub OIDC instead of long-lived AWS access keys
Restricted IAM trust policy
Least-privilege IAM permissions
S3 public access blocking
S3 encryption
S3 versioning
Remote Terraform state
Native Terraform state locking
Environment approval gates
Terraform validation before deployment
Terraform plan artifacts
Terraform state excluded from Git


What This Project Demonstrates

This project demonstrates practical DevOps and cloud infrastructure concepts:

Infrastructure as Code

Infrastructure is defined declaratively using Terraform.

Reusable Modules

Common infrastructure is implemented once and reused across environments.

Multi-Environment Infrastructure

Dev, Staging, and Production use the same modules with different configuration.

Remote State

Terraform state is stored centrally in Amazon S3.

State Locking

Native S3 state locking helps prevent concurrent state modifications.

CI/CD

GitHub Actions automatically validates, plans, and deploys infrastructure.

Cloud Authentication

GitHub Actions authenticates to AWS using OIDC rather than permanent credentials.

Deployment Governance

Staging and Production require explicit approval before deployment.

Security

The deployment role uses a custom least-privilege IAM policy instead of AdministratorAccess.

Author

Shivashankar Bansode

DevOps / Cloud Engineering Portfolio Project

Technologies:

Terraform
AWS
GitHub Actions
IAM
OIDC
EC2
VPC
S3
