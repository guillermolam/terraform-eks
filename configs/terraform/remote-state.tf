# remote-state.tf
# Terraform backend configuration for remote state storage

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend configuration for remote state
  backend "s3" {
    # These values should be configured via backend config file or CLI
    # Example: terraform init -backend-config=backend.hcl
    
    # bucket         = "your-terraform-state-bucket"
    # key            = "terraform-eks/terraform.tfstate"
    # region         = "eu-west-2"
    # dynamodb_table = "terraform-state-lock"
    # encrypt        = true
    # versioning     = true
    
    # Workspace-specific state paths
    # workspace_key_prefix = "workspaces"
  }
}

# Data source to get current workspace information
data "terraform_remote_state" "shared" {
  count   = var.use_shared_state ? 1 : 0
  backend = "s3"
  
  config = {
    bucket = var.shared_state_bucket
    key    = var.shared_state_key
    region = var.aws_region
  }
}

# Local values for state management
locals {
  # Generate workspace-specific state key
  state_key = "${var.project_name}/${terraform.workspace}/terraform.tfstate"
  
  # Tags for state-related resources
  state_tags = {
    Project     = var.project_name
    Environment = terraform.workspace
    ManagedBy   = "terraform"
    Component   = "state-management"
  }
}

# Output current workspace and state information
output "workspace_info" {
  description = "Current workspace and state information"
  value = {
    workspace    = terraform.workspace
    state_key    = local.state_key
    aws_region   = var.aws_region
    project_name = var.project_name
  }
}

# Variables for remote state configuration
variable "use_shared_state" {
  description = "Whether to use shared state from another Terraform configuration"
  type        = bool
  default     = false
}

variable "shared_state_bucket" {
  description = "S3 bucket name for shared Terraform state"
  type        = string
  default     = ""
}

variable "shared_state_key" {
  description = "S3 key for shared Terraform state"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Name of the project for state organization"
  type        = string
  default     = "terraform-eks"
}

variable "aws_region" {
  description = "AWS region for state storage"
  type        = string
  default     = "eu-west-2"
}