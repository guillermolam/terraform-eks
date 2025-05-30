# configs/terraform/provider-config.tf
# Provider configuration templates for different environments and use cases
# These configurations ensure consistent provider setup across all modules

# AWS Provider configurations for different environments
locals {
  # Base AWS provider configuration
  base_aws_config = {
    region                          = var.aws_region
    skip_credentials_validation     = var.skip_credentials_validation
    skip_metadata_api_check        = var.skip_metadata_api_check
    skip_requesting_account_id     = var.skip_requesting_account_id
    skip_region_validation         = false
    max_retries                    = var.aws_max_retries
    
    # Default tags applied to all AWS resources
    default_tags = {
      tags = merge(local.common_tags, {
        TerraformManaged = "true"
        BackendType     = "s3"
        StateLocation   = "${local.backend_config.bucket}/${local.backend_config.key}"
      })
    }
    
    # Ignore tags that might be managed by other systems
    ignore_tags = {
      keys = [
        "aws:cloudformation:logical-id",
        "aws:cloudformation:stack-id",
        "aws:cloudformation:stack-name",
        "kubernetes.io/cluster/*",
        "kubernetes.io/created-for/pv/name",
        "kubernetes.io/created-for/pvc/name",
        "kubernetes.io/created-for/pvc/namespace"
      ]
      key_prefixes = [
        "aws:",
        "kubernetes.io/",
        "k8s.io/",
        "eks:",
        "alpha.eksctl.io/",
        "eksctl.io/"
      ]
    }
  }
  
  # Development environment AWS configuration
  dev_aws_config = merge(local.base_aws_config, {
    # More permissive settings for development
    skip_credentials_validation = true
    skip_metadata_api_check    = true
    
    # Development-specific assume role (if needed)
    assume_role = var.dev_assume_role_arn != "" ? [
      {
        role_arn     = var.dev_assume_role_arn
        session_name = "terraform-dev-${formatdate("YYYYMMDD-hhmm", timestamp())}"
        external_id  = var.dev_external_id
        policy       = var.dev_assume_role_policy
        tags = {
          TerraformSession = "dev"
          SessionPurpose   = "development"
        }
      }
    ] : []
    
    # Retry configuration for development
    retry_mode = "adaptive"
    
    # HTTP configuration for development
    http_proxy                 = var.dev_http_proxy
    https_proxy               = var.dev_https_proxy
    no_proxy                  = var.dev_no_proxy
    ca_bundle                 = var.dev_ca_bundle
    insecure                  = var.dev_insecure_tls
    
    # Additional development-specific settings
    ec2_metadata_service_endpoint          = var.dev_ec2_metadata_endpoint
    ec2_metadata_service_endpoint_mode     = var.dev_ec2_metadata_mode
    sts_endpoint                          = var.dev_sts_endpoint
    use_dualstack_endpoint                = false
    use_fips_endpoint                     = false
  })
  
  # Staging environment AWS configuration
  staging_aws_config = merge(local.base_aws_config, {
    # More strict settings for staging
    skip_credentials_validation = false
    skip_metadata_api_check    = false
    
    # Staging-specific assume role
    assume_role = var.staging_assume_role_arn != "" ? [
      {
        role_arn     = var.staging_assume_role_arn
        session_name = "terraform-staging-${formatdate("YYYYMMDD-hhmm", timestamp())}"
        external_id  = var.staging_external_id
        policy       = var.staging_assume_role_policy
        tags = {
          TerraformSession = "staging"
          SessionPurpose   = "staging-deployment"
        }
      }
    ] : []
    
    # Enhanced retry configuration
    retry_mode = "adaptive"
    max_retries = 5
    
    # Security settings
    use_fips_endpoint = var.enable_fips_endpoints
    
    # Forbidden accounts to prevent accidental deployment
    forbidden_account_ids = var.staging_forbidden_accounts
    allowed_account_ids   = var.staging_allowed_accounts
  })
  
  # Production environment AWS configuration
  prod_aws_config = merge(local.base_aws_config, {
    # Strict settings for production
    skip_credentials_validation = false
    skip_metadata_api_check    = false
    skip_requesting_account_id = false
    
    # Production assume role with enhanced security
    assume_role = var.prod_assume_role_arn != "" ? [
      {
        role_arn     = var.prod_assume_role_arn
        session_name = "terraform-prod-${formatdate("YYYYMMDD-hhmm", timestamp())}"
        external_id  = var.prod_external_id
        policy       = var.prod_assume_role_policy
        duration     = "1h"  # Shorter session duration for production
        tags = {
          TerraformSession = "production"
          SessionPurpose   = "production-deployment"
          RequiresMFA     = "true"
        }
      }
    ] : []
    
    # Conservative retry configuration
    retry_mode  = "standard"
    max_retries = 3
    
    # Enhanced security for production
    use_fips_endpoint     = true
    use_dualstack_endpoint = true
    
    # Strict account validation
    forbidden_account_ids = var.prod_forbidden_accounts
    allowed_account_ids   = [data.aws_caller_identity.current.account_id]
    
    # Custom endpoints for production (if using VPC endpoints)
    endpoints = var.prod_custom_endpoints
  })
}

# Kubernetes provider configurations
locals {
  # Base Kubernetes configuration
  base_k8s_config = {
    # Will be configured dynamically after EKS cluster creation
    host                   = ""
    cluster_ca_certificate = ""
    token                 = ""
    
    # Alternative authentication methods
    exec = var.k8s_use_exec_auth ? [
      {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args = [
          "eks",
          "get-token",
          "--cluster-name",
          var.cluster_name,
          "--region",
          var.aws_region,
          "--role-arn",
          var.k8s_exec_role_arn
        ]
        env = {
          AWS_PROFILE = var.k8s_aws_profile
        }
      }
    ] : []
    
    # Ignore annotations and labels managed by other systems
    ignore_annotations = [
      "cluster-autoscaler.kubernetes.io/safe-to-evict",
      "deployment.kubernetes.io/revision",
      "kubectl.kubernetes.io/last-applied-configuration",
      "control-plane.alpha.kubernetes.io/leader"
    ]
    
    ignore_labels = [
      "app.kubernetes.io/managed-by",
      "helm.sh/chart",
      "pod-template-hash"
    ]
    
    # Client configuration
    insecure                   = false
    client_certificate        = var.k8s_client_certificate
    client_key               = var.k8s_client_key
    username                 = var.k8s_username
    password                = var.k8s_password
    proxy_url               = var.k8s_proxy_url
    
    # TLS configuration
    tls_server_name = var.k8s_tls_server_name
  }
  
  # Environment-specific Kubernetes configurations
  dev_k8s_config = merge(local.base_k8s_config, {
    # More permissive for development
    insecure = var.dev_k8s_insecure
    
    # Development-specific exec configuration
    exec = var.k8s_use_exec_auth ? [
      {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args = [
          "eks",
          "get-token",
          "--cluster-name",
          "${var.project_name}-dev",
          "--region",
          var.aws_region
        ]
      }
    ] : []
  })
  
  staging_k8s_config = merge(local.base_k8s_config, {
    # Enhanced security for staging
    exec = var.k8s_use_exec_auth ? [
      {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args = [
          "eks",
          "get-token",
          "--cluster-name",
          "${var.project_name}-staging",
          "--region",
          var.aws_region,
          "--role-arn",
          var.staging_k8s_role_arn
        ]
      }
    ] : []
  })
  
  prod_k8s_config = merge(local.base_k8s_config, {
    # Maximum security for production
    exec = var.k8s_use_exec_auth ? [
      {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args = [
          "eks",
          "get-token",
          "--cluster-name",
          "${var.project_name}-prod",
          "--region",
          var.aws_region,
          "--role-arn",
          var.prod_k8s_role_arn
        ]
        env = {
          AWS_PROFILE = var.prod_aws_profile
        }
      }
    ] : []
    
    # Production-specific timeout settings
    timeout = "30s"
  })
}

# Helm provider configurations
locals {
  # Base Helm configuration
  base_helm_config = {
    # Kubernetes connection (same as kubernetes provider)
    kubernetes = {
      host                   = ""
      cluster_ca_certificate = ""
      token                 = ""
    }
    
    # Helm-specific settings
    helm_driver            = var.helm_driver
    plugins_path          = var.helm_plugins_path
    registry_config_path  = var.helm_registry_config_path
    repository_config_path = var.helm_repository_config_path
    repository_cache      = var.helm_repository_cache
    debug                = var.helm_debug
    
    # Burst and QPS settings for large deployments
    burst_limit = var.helm_burst_limit
    qps        = var.helm_qps
    
    # Timeout settings
    timeout = var.helm_timeout
    
    # Experimental features
    experiments = {
      manifest = var.helm_enable_manifest_experiment
    }
  }
  
  # Environment-specific Helm configurations
  dev_helm_config = merge(local.base_helm_config, {
    debug = true
    timeout = "600s"  # Longer timeout for development
    
    # Development-specific Kubernetes connection
    kubernetes = {
      exec = var.k8s_use_exec_auth ? [
        {
          api_version = "client.authentication.k8s.io/v1beta1"
          command     = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            "${var.project_name}-dev",
            "--region",
            var.aws_region
          ]
        }
      ] : []
    }
  })
  
  staging_helm_config = merge(local.base_helm_config, {
    debug = false
    timeout = "300s"
    
    kubernetes = {
      exec = var.k8s_use_exec_auth ? [
        {
          api_version = "client.authentication.k8s.io/v1beta1"
          command     = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            "${var.project_name}-staging",
            "--region",
            var.aws_region,
            "--role-arn",
            var.staging_k8s_role_arn
          ]
        }
      ] : []
    }
  })
  
  prod_helm_config = merge(local.base_helm_config, {
    debug = false
    timeout = "300s"
    
    # Production-specific security
    kubernetes = {
      exec = var.k8s_use_exec_auth ? [
        {
          api_version = "client.authentication.k8s.io/v1beta1"
          command     = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            "${var.project_name}-prod",
            "--region",
            var.aws_region,
            "--role-arn",
            var.prod_k8s_role_arn
          ]
          env = {
            AWS_PROFILE = var.prod_aws_profile
          }
        }
      ] : []
    }
  })
}

# Provider configuration selector
locals {
  # Select configuration based on environment
  aws_config = var.environment == "prod" ? local.prod_aws_config : (
    var.environment == "staging" ? local.staging_aws_config : local.dev_aws_config
  )
  
  k8s_config = var.environment == "prod" ? local.prod_k8s_config : (
    var.environment == "staging" ? local.staging_k8s_config : local.dev_k8s_config
  )
  
  helm_config = var.environment == "prod" ? local.prod_helm_config : (
    var.environment == "staging" ? local.staging_helm_config : local.dev_helm_config
  )
}

# Additional provider configurations for specific use cases
locals {
  # Provider aliases for multi-region deployments
  aws_aliases = {
    # Primary region (default)
    primary = local.aws_config
    
    # US East 1 for global resources
    us_east_1 = merge(local.aws_config, {
      region = "eu-east-1"
      alias  = "us_east_1"
    })
    
    # Replica region for DR
    replica = merge(local.aws_config, {
      region = var.replica_region
      alias  = "replica"
    })
    
    # Backup region
    backup = merge(local.aws_config, {
      region = var.backup_region
      alias  = "backup"
    })
  }