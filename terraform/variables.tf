# ---------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region to create things in."
}

variable "aws_profile" {
  description = "AWS profile"
}

variable "stack" {
  description = "Name of the stack."
  default     = "apprunner-workshop"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default     = "172.17.0.0/16"
}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "2"
}

variable "aws_ecr" {
  description = "AWS ECR "
}

# variable "container_image" {
#  description = "Docker image to run in the ECS cluster"
#  default     = "ibuchh/spring-petclinic-h2"
# }

variable "family" {
  description = "Family of the Task Definition"
  default     = "petclinic"
}

variable "container_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 80
}

variable "max_concurrency" {
  description = "AppRunner Instance MAX Concurrency"
  default     = 100
}

variable "max_size" {
  description = "AppRunner Instance MAX Size"
  default     = "10"
}

variable "min_size" {
  description = "AppRunner Instance MIN Size"
  default     = "2"
}

variable "db_instance_type" {
  description = "RDS instance type"
  default     = "db.t3.medium"
}

variable "db_name" {
  description = "RDS DB name"
  default     = "petclinic"
}

variable "db_user" {
  description = "RDS DB username"
  default     = "root"
}

# variable "db_password" {
#   description = "RDS DB password"
# }

variable "db_profile" {
  description = "RDS Profile"
  default     = "mysql"
}

variable "db_initialize_mode" {
  description = "RDS initialize"
  default     = "always"
}

# Source repo name and branch

variable "source_repo_name" {
  description = "Source repo name"
  type        = string
}

variable "source_repo_branch" {
  description = "Source repo branch"
  type        = string
}


# Image repo name for ECR

variable "image_repo_name" {
  description = "Image repo name"
  type        = string
}

variable "apprunner-service-role" {
  description = "This role gives App Runner permission to access ECR"
  default     = "petclinic"
}

variable "codebuild_cache_bucket_name" {
  description = "Bucketname to use for storing codebuild cache artifacts"
}
