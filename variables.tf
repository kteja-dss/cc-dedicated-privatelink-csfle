variable "confluent_cloud_api_key" {
  description = "The Confluent Cloud API Key (also referred to as Cloud API ID)."
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "The Confluent Cloud API Secret."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The AWS Region where the Confluent Cloud Network will be created (e.g., us-east-1)."
  type        = string
}

variable "aws_kms_key_id" {
  description = "The AWS KMS Key ID created in the AWS account for encryption."
  type        = string
}

variable "aws_account_id" {
  description = "The AWS Account ID (12 digits) connecting to Confluent Cloud."
  type        = string
  validation {
    condition     = can(regex("^\\d{12}$", var.aws_account_id))
    error_message = "The AWS Account ID must be a 12-digit number."
  }
}

variable "vpc_id" {
  description = "The AWS VPC ID to private link to Confluent Cloud."
  type        = string
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "The VPC ID must start with 'vpc-'."
  }
}

variable "subnets_to_privatelink" {
  description = "A map of Zone ID to Subnet ID (e.g.: {\"use1-az1\" = \"subnet-abcdef0123456789a\"})."
  type        = map(string)
}

variable "aws_key" {
  description = "The AWS API Access Key (with permission to invoke Lambda or required services)."
  type        = string
}

variable "aws_secret" {
  description = "The AWS API Secret Key."
  type        = string
  sensitive   = true
}
