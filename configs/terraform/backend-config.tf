# configs/terraform/backend-config.tf
# Backend configuration templates for different environments
# These configurations support S3 backend with DynamoDB locking

# Development environment backend configuration
locals {
  dev_backend_config = {
    bucket         = "terraform-state-${var.project_name}-dev-${random_id.state_bucket_suffix.hex}"
    key            = "terraform/dev/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "terraform-locks-${var.project_name}-dev"
    encrypt        = true
    
    # S3 bucket versioning and lifecycle
    versioning_enabled = true
    
    # Server-side encryption
    server_side_encryption_configuration = {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm     = "aws:kms"
          kms_master_key_id = "alias/terraform-state-key-dev"
        }
        bucket_key_enabled = true
      }
    }
    
    # Public access block
    public_access_block = {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
    
    # Lifecycle configuration
    lifecycle_configuration = {
      rule = [
        {
          id     = "state_file_lifecycle"
          status = "Enabled"
          
          noncurrent_version_expiration = {
            noncurrent_days = 90
          }
          
          noncurrent_version_transition = [
            {
              noncurrent_days = 30
              storage_class   = "STANDARD_IA"
            },
            {
              noncurrent_days = 60
              storage_class   = "GLACIER"
            }
          ]
        }
      ]
    }
    
    # Bucket notifications for state changes
    notification_configuration = {
      topic = [
        {
          topic_arn = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:terraform-state-changes-dev"
          events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
        }
      ]
    }
    
    # Cross-region replication (optional)
    replication_configuration = var.enable_cross_region_replication ? {
      role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-state-replication-role"
      
      rules = [
        {
          id       = "ReplicateToSecondaryRegion"
          status   = "Enabled"
          priority = 1
          
          destination = {
            bucket        = "terraform-state-${var.project_name}-dev-replica-${random_id.state_bucket_suffix.hex}"
            storage_class = "STANDARD_IA"
            
            encryption_configuration = {
              replica_kms_key_id = "alias/terraform-state-key-dev"
            }
          }
        }
      ]
    } : null
  }
  
  # Staging environment backend configuration
  staging_backend_config = {
    bucket         = "terraform-state-${var.project_name}-staging-${random_id.state_bucket_suffix.hex}"
    key            = "terraform/staging/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "terraform-locks-${var.project_name}-staging"
    encrypt        = true
    
    # Enhanced security for staging
    versioning_enabled = true
    mfa_delete        = var.enable_mfa_delete
    
    server_side_encryption_configuration = {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm     = "aws:kms"
          kms_master_key_id = "alias/terraform-state-key-staging"
        }
        bucket_key_enabled = true
      }
    }
    
    public_access_block = {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
    
    # More aggressive lifecycle for staging
    lifecycle_configuration = {
      rule = [
        {
          id     = "state_file_lifecycle"
          status = "Enabled"
          
          noncurrent_version_expiration = {
            noncurrent_days = 60
          }
          
          noncurrent_version_transition = [
            {
              noncurrent_days = 14
              storage_class   = "STANDARD_IA"
            },
            {
              noncurrent_days = 30
              storage_class   = "GLACIER"
            }
          ]
        }
      ]
    }
    
    # Enable logging for staging
    logging = {
      target_bucket = "terraform-access-logs-${var.project_name}-staging"
      target_prefix = "state-access-logs/"
    }
  }
  
  # Production environment backend configuration
  prod_backend_config = {
    bucket         = "terraform-state-${var.project_name}-prod-${random_id.state_bucket_suffix.hex}"
    key            = "terraform/prod/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "terraform-locks-${var.project_name}-prod"
    encrypt        = true
    
    # Maximum security for production
    versioning_enabled = true
    mfa_delete         = true
    
    server_side_encryption_configuration = {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm     = "aws:kms"
          kms_master_key_id = "alias/terraform-state-key-prod"
        }
        bucket_key_enabled = true
      }
    }
    
    public_access_block = {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
    
    # Conservative lifecycle for production
    lifecycle_configuration = {
      rule = [
        {
          id     = "state_file_lifecycle"
          status = "Enabled"
          
          noncurrent_version_expiration = {
            noncurrent_days = 365
          }
          
          noncurrent_version_transition = [
            {
              noncurrent_days = 90
              storage_class   = "STANDARD_IA"
            },
            {
              noncurrent_days = 180
              storage_class   = "GLACIER"
            },
            {
              noncurrent_days = 270
              storage_class   = "DEEP_ARCHIVE"
            }
          ]
        }
      ]
    }
    
    # Comprehensive monitoring for production
    notification_configuration = {
      topic = [
        {
          topic_arn = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:terraform-state-changes-prod"
          events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
        }
      ]
      
      cloudwatchconfigurations = [
        {
          cloudwatch_configuration = {
            log_group_name = "/aws/s3/terraform-state-prod"
          }
        }
      ]
    }
    
    # Mandatory cross-region replication for production
    replication_configuration = {
      role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-state-replication-role-prod"
      
      rules = [
        {
          id       = "ReplicateToSecondaryRegion"
          status   = "Enabled"
          priority = 1
          
          destination = {
            bucket        = "terraform-state-${var.project_name}-prod-replica-${random_id.state_bucket_suffix.hex}"
            storage_class = "STANDARD"
            
            encryption_configuration = {
              replica_kms_key_id = "alias/terraform-state-key-prod"
            }
            
            # Access control translation for cross-account replication
            access_control_translation = {
              owner = "Destination"
            }
          }
        }
      ]
    }
    
    # Enable access logging
    logging = {
      target_bucket = "terraform-access-logs-${var.project_name}-prod"
      target_prefix = "state-access-logs/"
    }
    
    # Object lock for compliance
    object_lock_configuration = {
      object_lock_enabled = "Enabled"
      
      rule = {
        default_retention = {
          mode = "GOVERNANCE"
          days = 30
        }
      }
    }
  }
}

# Random ID for bucket suffix to ensure global uniqueness
resource "random_id" "state_bucket_suffix" {
  byte_length = 4
}

# Backend configuration selector based on environment
locals {
  backend_config = var.environment == "prod" ? local.prod_backend_config : (
    var.environment == "staging" ? local.staging_backend_config : local.dev_backend_config
  )
}

# DynamoDB table configuration for state locking
locals {
  dynamodb_table_config = {
    name           = local.backend_config.dynamodb_table
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "LockID"
    
    attributes = [
      {
        name = "LockID"
        type = "S"
      }
    ]
    
    # Enable point-in-time recovery for production
    point_in_time_recovery_enabled = var.environment == "prod"
    
    # Server-side encryption
    server_side_encryption = {
      enabled     = true
      kms_key_arn = "alias/terraform-locks-key-${var.environment}"
    }
    
    # Tags
    tags = merge(local.common_tags, {
      Name        = local.backend_config.dynamodb_table
      Purpose     = "terraform-state-locking"
      Environment = var.environment
    })
    
    # Backup configuration for production
    backup_policy = var.environment == "prod" ? {
      # Enable continuous backups
      point_in_time_recovery_enabled = true
      
      # Scheduled backups
      backup_plan = {
        name = "terraform-locks-backup-${var.environment}"
        
        rule = [
          {
            rule_name         = "daily_backup"
            target_vault_name = "terraform-backup-vault"
            schedule          = "cron(0 2 * * ? *)"  # Daily at 2 AM
            
            lifecycle = {
              cold_storage_after = 30
              delete_after      = 365
            }
            
            recovery_point_tags = {
              BackupType = "scheduled"
              Environment = var.environment
            }
          }
        ]
      }
    } : null
  }
}

# S3 bucket policy for enhanced security
data "aws_iam_policy_document" "state_bucket_policy" {
  # Deny all non-SSL requests
  statement {
    sid       = "DenyNonSSLRequests"
    effect    = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.backend_config.bucket}",
      "arn:aws:s3:::${local.backend_config.bucket}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  
  # Restrict access to specific IAM roles/users
  statement {
    sid    = "RestrictToAuthorizedPrincipals"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-execution-role",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-ci-role"
      ]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.backend_config.bucket}",
      "arn:aws:s3:::${local.backend_config.bucket}/*"
    ]
  }
  
  # Prevent public access
  statement {
    sid       = "DenyPublicAccess"
    effect    = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.backend_config.bucket}",
      "arn:aws:s3:::${local.backend_config.bucket}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalServiceName"
      values   = ["terraform.io"]
    }
  }
}

# Output backend configuration for use in terraform init
output "backend_config" {
  description = "Backend configuration for terraform init"
  value = {
    bucket         = local.backend_config.bucket
    key            = local.backend_config.key
    region         = local.backend_config.region
    dynamodb_table = local.backend_config.dynamodb_table
    encrypt        = local.backend_config.encrypt
  }
}

# Output backend configuration as HCL for files
output "backend_config_hcl" {
  description = "Backend configuration in HCL format for backend config files"
  value = <<-EOF
    bucket         = "${local.backend_config.bucket}"
    key            = "${local.backend_config.key}"
    region         = "${local.backend_config.region}"
    dynamodb_table = "${local.backend_config.dynamodb_table}"
    encrypt        = ${local.backend_config.encrypt}
  EOF
}

# Validation rules
locals {
  backend_validation = {
    # Ensure bucket name follows naming conventions
    valid_bucket_name = can(regex("^terraform-state-[a-z0-9-]+-[a-z0-9]+$", local.backend_config.bucket))
    
    # Ensure DynamoDB table follows naming conventions
    valid_table_name = can(regex("^terraform-locks-[a-z0-9-]+$", local.backend_config.dynamodb_table))
    
    # Ensure encryption is enabled
    encryption_enabled = local.backend_config.encrypt == true
    
    # Ensure key follows pattern
    valid_key_pattern = can(regex("^terraform/.+/terraform\\.tfstate$", local.backend_config.key))
  }
}

# Validation checks
check "backend_configuration" {
  assert {
    condition     = local.backend_validation.valid_bucket_name
    error_message = "Backend bucket name must follow the pattern: terraform-state-{project}-{env}-{suffix}"
  }
  
  assert {
    condition     = local.backend_validation.valid_table_name
    error_message = "DynamoDB table name must follow the pattern: terraform-locks-{project}-{env}"
  }
  
  assert {
    condition     = local.backend_validation.encryption_enabled
    error_message = "Backend encryption must be enabled for security compliance"
  }
  
  assert {
    condition     = local.backend_validation.valid_key_pattern
    error_message = "Backend key must follow the pattern: terraform/{env}/terraform.tfstate"
  }
}