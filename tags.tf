
resource "confluent_tag" "pii" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.essentials.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.essentials.rest_endpoint
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }

  name        = "PII"
  description = "PII tag for encrypting the csfle fields"

  lifecycle {
    prevent_destroy = false
  }
}
