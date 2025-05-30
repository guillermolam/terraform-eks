# terraform.tf
# Main Terraform configuration for EKS Zero-Trust project
# This file contains provider configurations, backend setup, and global settings

terraform {
  # Terraform version constraint
  required_version = ">= 1.12.0"

  # Required providers with version constraints
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }

  # Backend configuration for remote state
  # This will be overridden by backend config files in environments
  backend "s3" {
    # Default backend configuration
    # Actual values will be provided via backend config files
    encrypt = true

    # Backend configuration will be provided via:
    # terraform init -backend-config=backend.hcl
  }

  # Experimental features (Terraform 1.12+)
  experiments = [
    "terraform_stacks",  # Enable Terraform Stacks for modular deployments
    "sensitive_outputs", # Enable sensitive outputs to prevent accidental exposure
    "resource_splits"    # Enable resource splits for better state manageme
    # Enable Terraform Stacks (if using stacks)
    # Note: Remove this if not using experimental features
  ]
}

# Default AWS provider configuration
# This can be overridden in environment-specific configurations
provider "aws" {
  # Default region - can be overridden by environment variables or backend config
  region = var.aws_region

  # Default tags applied to all resources
  default_tags {
    tags = {
      Project             = var.project_name
      Environment         = var.environment
      ManagedBy           = "terraform"
      Owner               = var.owner
      CostCenter          = var.cost_center
      SecurityLevel       = var.security_level
      BackupRequired      = var.backup_required
      MonitoringEnabled   = var.monitoring_enabled
      ComplianceFramework = var.compliance_framework
      CreatedDate         = formatdate("YYYY-MM-DD", timestamp())
      Repository          = var.repository_url
    }
  }

  # Assume role configuration for cross-account access
  dynamic "assume_role" {
    for_each = var.assume_role_arn != "" ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = "terraform-eks-${var.environment}"
      external_id  = var.external_id
    }
  }

  # Skip metadata API check for environments where it's not available
  skip_metadata_api_check = var.skip_metadata_api_check

  # Skip requesting account ID to avoid unnecessary API calls
  skip_requesting_account_id = var.skip_requesting_account_id

  # Skip credentials validation for specific use cases
  skip_credentials_validation = var.skip_credentials_validation

  # Maximum retries for AWS API calls
  max_retries = var.max_retries

  # Ignore tags on resources not managed by Terraform
  ignore_tags {
    keys         = var.ignore_tag_keys
    key_prefixes = var.ignore_tag_key_prefixes
  }

  # Forbidden account IDs to prevent accidental resource creation
  forbidden_account_ids = var.forbidden_account_ids

  # Allowed account IDs for additional security
  allowed_account_ids = var.allowed_account_ids
}

# Kubernetes provider configuration
# This will be configured after EKS cluster creation
provider "kubernetes" {
  # Configuration will be provided dynamically after cluster creation
  host                   = try(data.aws_eks_cluster.cluster[0].endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      try(data.aws_eks_cluster.cluster[0].name, ""),
      "--region",
      var.aws_region,
    ]
  }

  # Ignore annotations and labels that are managed by other systems
  ignore_annotations = var.k8s_ignore_annotations
  ignore_labels      = var.k8s_ignore_labels
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = try(data.aws_eks_cluster.cluster[0].endpoint, "")
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        try(data.aws_eks_cluster.cluster[0].name, ""),
        "--region",
        var.aws_region,
      ]
    }
  }

  # Helm-specific configuration
  repository_config_path = var.helm_repository_config_path
  repository_cache       = var.helm_repository_cache
  debug                  = var.helm_debug
  plugins_path           = var.helm_plugins_path
  registry_config_path   = var.helm_registry_config_path
}

# Kubectl provider configuration
provider "kubectl" {
  host                   = try(data.aws_eks_cluster.cluster[0].endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      try(data.aws_eks_cluster.cluster[0].name, ""),
      "--region",
      var.aws_region,
    ]
  }
}

# Data sources for dynamic provider configuration
data "aws_eks_cluster" "cluster" {
  count = var.cluster_name != "" ? 1 : 0
  name  = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.cluster_name != "" ? 1 : 0
  name  = var.cluster_name
}

# Current AWS caller identity
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Available AWS availability zones
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# AWS partition information
data "aws_partition" "current" {}

# Local values for common configurations
locals {
  # Account and region information
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name

  # Common name prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Availability zones
  azs = slice(data.aws_availability_zones.available.names, 0, var.max_availability_zones)

  # Common tags that will be merged with resource-specific tags
  common_tags = {
    Project             = var.project_name
    Environment         = var.environment
    ManagedBy           = "terraform"
    Owner               = var.owner
    CostCenter          = var.cost_center
    SecurityLevel       = var.security_level
    BackupRequired      = var.backup_required
    MonitoringEnabled   = var.monitoring_enabled
    ComplianceFramework = var.compliance_framework
    AccountId           = local.account_id
    Region              = local.region
    AvailabilityZones   = join(",", local.azs)
    CreatedDate         = formatdate("YYYY-MM-DD", timestamp())
    Repository          = var.repository_url
    TerraformVersion    = "1.12+"
    ProviderVersions = jsonencode({
      aws        = "~> 5.70"
      kubernetes = "~> 2.33"
      helm       = "~> 2.15"
      kubectl    = "~> 2.0"
    })
  }

  # Security configuration
  enable_encryption = var.environment == "prod" ? true : var.enable_encryption
  enable_logging    = var.environment == "prod" ? true : var.enable_logging

  # Network configuration
  enable_ipv6 = var.enable_ipv6

  # Kubernetes configuration
  cluster_endpoint_private_access = var.environment == "prod" ? true : var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.environment == "prod" ? false : var.cluster_endpoint_public_access

  # Monitoring and observability
  enable_container_insights = var.enable_container_insights
  enable_cloudtrail         = var.environment == "prod" ? true : var.enable_cloudtrail

  # Backup and disaster recovery
  backup_retention_days = var.environment == "prod" ? 30 : var.backup_retention_days

  # Cost optimization
  enable_spot_instances = var.environment != "prod" ? var.enable_spot_instances : false
}

# Terraform Cloud/Enterprise configuration (optional)
# Uncomment if using Terraform Cloud or Enterprise
/*
cloud {
  organization = var.terraform_cloud_organization

  workspaces {
    tags = [
      var.project_name,
      var.environment,
      "eks",
      "zero-trust"
    ]
  }
}
*/
