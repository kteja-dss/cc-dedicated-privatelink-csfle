
# Optional: Create an alias for the KMS Key
resource "aws_kms_alias" "my_kms_key_alias" {
  name          = "alias/my-kms-key"
  target_key_id = var.aws_kms_key_id
}

data "external" "update_kms_policy" {
  program = ["bash", "${path.module}/update_kms_policy.sh"]

  query = {
    rest_endpoint  = confluent_schema_registry_kek.csfle_key.rest_endpoint
    key            = confluent_schema_registry_kek.csfle_key.credentials[0].key
    secret         = confluent_schema_registry_kek.csfle_key.credentials[0].secret
    kms_key_id     = var.aws_kms_key_id
    aws_access_key = var.aws_key
    aws_secret_key = var.aws_secret
    aws_region     = var.region
  }
}

# Existing Confluent Schema Registry KEK configuration
resource "confluent_schema_registry_kek" "csfle_key" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.essentials.id
  }

  rest_endpoint = data.confluent_schema_registry_cluster.essentials.rest_endpoint

  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }

  name        = "my_kek"           # Name of the KEK
  kms_type    = "aws-kms"          # Specify that the KEK is managed by AWS KMS
  kms_key_id  = var.aws_kms_key_id # Reference the AWS KMS Key ID
  doc         = "Key Encryption Key for Confluent Schema Registry"
  shared      = true
  hard_delete = true



  lifecycle {
    prevent_destroy = false
  }
}



