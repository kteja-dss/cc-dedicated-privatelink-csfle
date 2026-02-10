# Terraform AWS PrivateLink with CSFLE and Policy Update

This Terraform project provisions a Confluent Cloud environment with AWS PrivateLink and Client-Side Field Level Encryption (CSFLE) enabled. It also includes a script to update the AWS KMS Key Policy to allow Confluent Cloud to access the key.

## Prerequisites

- **Terraform** (v1.0+)
- **AWS CLI** (configured with appropriate permissions)
- **jq** (required for the external data script)
- **curl** (required for the external data script)
- **Confluent Cloud Account** (and API keys)

## Project Structure

- `main.tf`: Core resources (Environment, Kafka Cluster, PrivateLink, Service Accounts).
- `aws.tf`: AWS-specific resources for PrivateLink (VPC Endpoint, Security Group, Route53).
- `csfle.tf`: CSFLE configuration and KMS integration.
- `schema-registry.tf`: Schema Registry resources and schemas.
- `variables.tf`: Input variables.
- `outputs.tf`: Output values.
- `providers.tf`: Provider configurations.
- `update_kms_policy.sh`: Helper script to update AWS KMS Policy.

## Usage

1.  **Initialize Terraform:**

    ```bash
    terraform init
    ```

2.  **Create a `terraform.tfvars` file** with your configuration:

    ```hcl
    confluent_cloud_api_key    = "YOUR_KEY"
    confluent_cloud_api_secret = "YOUR_SECRET"
    region                     = "us-east-1"
    aws_kms_key_id             = "alias/your-kms-key" # or UUID
    aws_account_id             = "123456789012"
    vpc_id                     = "vpc-xxxxxxxx"
    subnets_to_privatelink     = {
      "us-east-1a" = "subnet-xxxxxx"
      "us-east-1b" = "subnet-yyyyyy"
    }
    aws_key                    = "YOUR_AWS_ACCESS_KEY"
    aws_secret                 = "YOUR_AWS_SECRET_KEY"
    ```

3.  **Plan the deployment:**

    ```bash
    terraform plan -out=tfplan
    ```

4.  **Apply the changes:**

    ```bash
    terraform apply tfplan
    ```

## Notes

- The `update_kms_policy.sh` script is called by Terraform to fetch the required Key Encryption Key (KEK) policy from Confluent Cloud and merge it with your existing AWS KMS Key Policy. **Note:** This script uses `aws configure set` which may modify your local AWS profile settings.
- Ensure your AWS credentials have permissions to manage KMS policies and VPC Endpoints.
