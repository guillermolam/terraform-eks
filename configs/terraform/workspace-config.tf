# workspace-config.tf
# Workspace-specific configurations and variables

# Local values for workspace-specific configurations
locals {
  # Environment mapping based on workspace name
  environment = terraform.workspace == "default" ? "dev" : terraform.workspace
  
  # Workspace-specific configurations
  workspace_config = {
    dev = {
      # Development environment settings
      cluster_version     = "1.30"
      node_instance_types = ["t3.medium", "t3.large"]
      desired_capacity    = 2
      min_capacity        = 1
      max_capacity        = 5
      disk_size          = 20
      
      # Networking
      availability_zones = 2
      enable_nat_gateway = true
      single_nat_gateway = true
      
      # Features
      enable_cluster_autoscaler = true
      enable_aws_load_balancer_controller = true
      enable_cert_manager = true
      enable_external_dns = false
      enable_monitoring = false
      
      # Security
      enable_irsa = true
      enable_encryption = false
      
      # Cost optimization
      enable_spot_instances = true
      spot_instance_types = ["t3.medium", "t3.large"]
    }
    
    staging = {
      # Staging environment settings
      cluster_version     = "1.30"
      node_instance_types = ["t3.large", "t3.xlarge"]
      desired_capacity    = 3
      min_capacity        = 2
      max_capacity        = 10
      disk_size          = 50
      
      # Networking
      availability_zones = 3
      enable_nat_gateway = true
      single_nat_gateway = false
      
      # Features
      enable_cluster_autoscaler = true
      enable_aws_load_balancer_controller = true
      enable_cert_manager = true
      enable_external_dns = true
      enable_monitoring = true
      
      # Security
      enable_irsa = true
      enable_encryption = true
      
      # Cost optimization
      enable_spot_instances = true
      spot_instance_types = ["t3.large", "t3.xlarge"]
    }
    
    prod = {
      # Production environment settings
      cluster_version     = "1.30"
      node_instance_types = ["m5.large", "m5.xlarge", "m5.2xlarge"]
      desired_capacity    = 5
      min_capacity        = 3
      max_capacity        = 20
      disk_size          = 100
      
      # Networking
      availability_zones = 3
      enable_nat_gateway = true
      single_nat_gateway = false
      
      # Features
      enable_cluster_autoscaler = true
      enable_aws_load_balancer_controller = true
      enable_cert_manager = true
      enable_external_dns = true
      enable_monitoring = true
      
      # Security
      enable_irsa = true
      enable_encryption = true
      
      # Cost optimization
      enable_spot_instances = false
      spot_instance_types = []
    }
  }
  
  # Get current workspace configuration
  current_config = local.workspace_config[local.environment]
  
  # Common tags for all resources
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    Workspace   = terraform.workspace
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
  
  # Resource naming convention
  name_prefix = "${var.project_name}-${local.environment}"
  
  # Cluster name
  cluster_name = "${local.name_prefix}-eks"
  
  # VPC name
  vpc_name = "${local.name_prefix}-vpc"
}

# Variables for workspace configuration
variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

# Workspace validation
resource "null_resource" "workspace_validation" {
  count = contains(keys(local.workspace_config), local.environment) ? 0 : 1
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Invalid workspace ${terraform.workspace}. Valid workspaces: ${join(", ", keys(local.workspace_config))}' && exit 1"
  }
}

# Outputs for workspace configuration
output "workspace_config" {
  description = "Current workspace configuration"
  value = {
    environment    = local.environment
    workspace      = terraform.workspace
    cluster_name   = local.cluster_name
    vpc_name       = local.vpc_name
    name_prefix    = local.name_prefix
    config         = local.current_config
    common_tags    = local.common_tags
  }
}

output "cluster_config" {
  description = "EKS cluster configuration for current workspace"
  value = {
    cluster_name        = local.cluster_name
    cluster_version     = local.current_config.cluster_version
    node_instance_types = local.current_config.node_instance_types
    desired_capacity    = local.current_config.desired_capacity
    min_capacity        = local.current_config.min_capacity
    max_capacity        = local.current_config.max_capacity
    disk_size          = local.current_config.disk_size
  }
}

output "networking_config" {
  description = "Networking configuration for current workspace"
  value = {
    vpc_name           = local.vpc_name
    availability_zones = local.current_config.availability_zones
    enable_nat_gateway = local.current_config.enable_nat_gateway
    single_nat_gateway = local.current_config.single_nat_gateway
  }
}

output "feature_flags" {
  description = "Feature flags for current workspace"
  value = {
    enable_cluster_autoscaler           = local.current_config.enable_cluster_autoscaler
    enable_aws_load_balancer_controller = local.current_config.enable_aws_load_balancer_controller
    enable_cert_manager                 = local.current_config.enable_cert_manager
    enable_external_dns                 = local.current_config.enable_external_dns
    enable_monitoring                   = local.current_config.enable_monitoring
    enable_irsa                         = local.current_config.enable_irsa
    enable_encryption                   = local.current_config.enable_encryption
    enable_spot_instances               = local.current_config.enable_spot_instances
  }
}