terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.46"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.2.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# https://docs.confluent.io/cloud/current/networking/peering/aws-peering.html
# Create a VPC Peering Connection to Confluent Cloud on AWS
provider "aws" {
  region     = var.region
  access_key = var.aws_key
  secret_key = var.aws_secret
}
