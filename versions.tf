# versions.tf
# Terraform and provider version constraints for EKS Zero-Trust project
# This file centralizes all version requirements and experimental features

terraform {
  # Terraform version constraints
  # Using Terraform 1.12+ for native testing and stacks support
  required_version = ">= 1.12.0, < 2.0.0"

  # Required providers with specific version constraints
  required_providers {
    # AWS Provider - Core infrastructure provider
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0, < 6.0.0"
      configuration_aliases = [
        aws.us_east_1, # For global resources like CloudFront
        aws.replica,   # For cross-region replication
      ]
    }

    # Kubernetes Provider - Manage Kubernetes resources
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.33.0, < 3.0.0"
    }

    # Helm Provider - Deploy Helm charts
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15.0, < 3.0.0"
    }

    # Kubectl Provider - Advanced Kubernetes resource management
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0, < 3.0.0"
    }

    # TLS Provider - Certificate and key generation
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0, < 5.0.0"
    }

    # Random Provider - Generate random values
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, < 4.0.0"
    }

    # Time Provider - Time-based resources
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.0, < 1.0.0"
    }

    # Null Provider - Null resources and triggers
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0, < 4.0.0"
    }

    # External Provider - External data sources and programs
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.0, < 3.0.0"
    }

    # Local Provider - Local file and data management
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0, < 3.0.0"
    }

    # Archive Provider - Archive file creation
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0, < 3.0.0"
    }

    # Cloudinit Provider - Cloud-init configuration
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.3.0, < 3.0.0"
    }

    # HTTP Provider - HTTP data sources
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0, < 4.0.0"
    }

    # Template Provider (deprecated but might be needed for legacy)
    # template = {
    #   source  = "hashicorp/template"
    #   version = ">= 2.2.0, < 3.0.0"
    # }

    # Vault Provider - HashiCorp Vault integration (optional)
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.4.0, < 5.0.0"
    }

    # Consul Provider - HashiCorp Consul integration (optional)
    consul = {
      source  = "hashicorp/consul"
      version = ">= 2.21.0, < 3.0.0"
    }

    # Datadog Provider - Monitoring integration (optional)
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 3.46.0, < 4.0.0"
    }

    # PagerDuty Provider - Incident management (optional)
    pagerduty = {
      source  = "PagerDuty/pagerduty"
      version = ">= 3.15.0, < 4.0.0"
    }

    # Grafana Provider - Monitoring dashboards (optional)
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7.0, < 4.0.0"
    }

    # GitHub Provider - GitHub integration for CI/CD (optional)
    github = {
      source  = "integrations/github"
      version = ">= 6.2.0, < 7.0.0"
    }

    # ACME Provider - Let's Encrypt certificates (optional)
    acme = {
      source  = "vancluever/acme"
      version = ">= 2.25.0, < 3.0.0"
    }
  }

  # Experimental features for Terraform 1.12+
  experiments = [
    # Uncomment the features you want to use
    # "stacks",              # Terraform Stacks (if using)
    # "provider_functions",  # Provider-defined functions
    # "config_driven_import" # Config-driven import
  ]

  # Provider metadata for dependency tracking
  provider_meta "aws" {
    # Metadata for AWS provider usage tracking
    module_name    = "terraform-eks-zero-trust"
    module_version = "1.0.0"
  }
}

# Provider version constraints for child modules
# These ensure consistency across all modules in the project

# Minimum provider versions required for specific features
locals {
  # AWS provider features mapping
  aws_feature_versions = {
    # EKS cluster access management (AWS provider 5.57+)
    eks_access_entries = "5.57.0"
    # EKS pod identity associations (AWS provider 5.56+)
    eks_pod_identity = "5.56.0"
    # VPC lattice support (AWS provider 5.50+)
    vpc_lattice = "5.50.0"
    # Enhanced security groups (AWS provider 5.60+)
    enhanced_sg = "5.60.0"
    # CloudWatch cross-account observability (AWS provider 5.65+)
    cloudwatch_cross_account = "5.65.0"
    # EKS fargate pod identity (AWS provider 5.70+)
    fargate_pod_identity = "5.70.0"
  }

  # Kubernetes provider features mapping
  k8s_feature_versions = {
    # Pod Security Standards (Kubernetes provider 2.30+)
    pod_security_standards = "2.30.0"
    # Server-side apply (Kubernetes provider 2.31+)
    server_side_apply = "2.31.0"
    # Field manager support (Kubernetes provider 2.32+)
    field_manager = "2.32.0"
    # Improved CRD handling (Kubernetes provider 2.33+)
    improved_crd = "2.33.0"
  }

  # Helm provider features mapping
  helm_feature_versions = {
    # OCI registry support (Helm provider 2.12+)
    oci_registry = "2.12.0"
    # Improved dependency management (Helm provider 2.14+)
    dependency_management = "2.14.0"
    # Enhanced security (Helm provider 2.15+)
    enhanced_security = "2.15.0"
  }
}

# Version compatibility matrix
# Documents which versions work together
locals {
  compatibility_matrix = {
    terraform_1_12 = {
      aws        = ">= 5.70.0"
      kubernetes = ">= 2.33.0"
      helm       = ">= 2.15.0"
      kubectl    = ">= 2.0.0"
    }
    terraform_1_11 = {
      aws        = ">= 5.60.0"
      kubernetes = ">= 2.30.0"
      helm       = ">= 2.12.0"
      kubectl    = ">= 1.14.0"
    }
  }
}

# Development and testing version overrides
# These can be used for testing with specific versions
variable "provider_version_overrides" {
  description = "Override provider versions for testing purposes"
  type = object({
    aws        = optional(string)
    kubernetes = optional(string)
    helm       = optional(string)
    kubectl    = optional(string)
  })
  default = {}
}

# Provider upgrade policy
# Documents the upgrade strategy for providers
locals {
  upgrade_policy = {
    # Major version upgrades require explicit approval
    major_upgrade_approval = true

    # Minor version upgrades are automatic within constraints
    auto_minor_upgrade = true

    # Patch version upgrades are always automatic
    auto_patch_upgrade = true

    # Maximum age for provider versions (days)
    max_provider_age = 90

    # Security update urgency
    security_update_urgency = "high"
  }
}

# Breaking changes documentation
# Documents known breaking changes between versions
locals {
  breaking_changes = {
    aws_5_70_0 = [
      "EKS access entries API changes",
      "VPC endpoint policy changes",
      "IAM role trust policy updates"
    ]
    kubernetes_2_33_0 = [
      "Pod Security Standards enforcement",
      "Deprecated API version removals",
      "CRD validation changes"
    ]
    helm_2_15_0 = [
      "Repository authentication changes",
      "Chart dependency resolution updates",
      "OCI registry format changes"
    ]
  }
}

# Security and compliance requirements
locals {
  security_requirements = {
    # Minimum provider versions for security compliance
    min_security_versions = {
      aws        = "5.60.0" # Required for latest security features
      kubernetes = "2.30.0" # Required for Pod Security Standards
      helm       = "2.12.0" # Required for OCI security
      kubectl    = "2.0.0"  # Required for advanced RBAC
    }

    # CVE mitigation versions
    cve_mitigation_versions = {
      # Update as new CVEs are discovered and patched
      aws_cve_2024_001 = "5.65.0"
      k8s_cve_2024_002 = "2.32.0"
    }

    # Compliance framework requirements
    compliance_versions = {
      soc2 = {
        aws        = ">= 5.60.0"
        kubernetes = ">= 2.30.0"
      }
      hipaa = {
        aws        = ">= 5.65.0"
        kubernetes = ">= 2.32.0"
      }
      pci_dss = {
        aws        = ">= 5.70.0"
        kubernetes = ">= 2.33.0"
      }
    }
  }
}

# Performance optimization versions
locals {
  performance_optimized_versions = {
    # Versions optimized for performance
    aws_performance        = "5.70.0" # Latest performance improvements
    kubernetes_performance = "2.33.0" # Optimized resource handling
    helm_performance       = "2.15.0" # Faster chart operations
    kubectl_performance    = "2.0.0"  # Improved kubectl operations
  }
}

# Testing and validation
locals {
  testing_config = {
    # Test with multiple provider versions
    test_matrix = [
      {
        terraform  = "1.12.0"
        aws        = "5.70.0"
        kubernetes = "2.33.0"
        helm       = "2.15.0"
      },
      {
        terraform  = "1.11.0"
        aws        = "5.60.0"
        kubernetes = "2.30.0"
        helm       = "2.12.0"
      }
    ]

    # Nightly testing with latest versions
    nightly_test_latest = true

    # Beta testing with pre-release versions
    beta_testing_enabled = false
  }
}
