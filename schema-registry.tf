resource "confluent_service_account" "env-manager" {
  display_name = "env-manager"
  description  = "Service account to manage the environment"
}

resource "confluent_role_binding" "env-manager-environment-admin" {
  principal   = "User:${confluent_service_account.env-manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.env.resource_name
}

resource "confluent_api_key" "env-manager-schema-registry-api-key" {
  display_name = "env-manager-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'env-manager' service account"
  owner {
    id          = confluent_service_account.env-manager.id
    api_version = confluent_service_account.env-manager.api_version
    kind        = confluent_service_account.env-manager.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.essentials.id
    api_version = data.confluent_schema_registry_cluster.essentials.api_version
    kind        = data.confluent_schema_registry_cluster.essentials.kind

    environment {
      id = confluent_environment.env.id
    }
  }

  # The goal is to ensure that confluent_role_binding.env-manager-environment-admin is created before
  # confluent_api_key.env-manager-schema-registry-api-key is used to create instances of
  # confluent_schema resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.env-manager-schema-registry-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_schema resources instead.
  depends_on = [
    confluent_role_binding.env-manager-environment-admin,
    confluent_private_link_access.aws,
    aws_vpc_endpoint.privatelink,
    aws_route53_record.privatelink,
    aws_route53_record.privatelink-zonal,
  ]
}


resource "confluent_schema" "banking-info" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.essentials.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.essentials.rest_endpoint
  subject_name  = "BankingInfo"
  format        = "AVRO"
  schema        = file("./schemas/avro/bankingInfo.avsc")
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
}

data "confluent_schema" "banking-info" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.essentials.id
  }
  rest_endpoint     = data.confluent_schema_registry_cluster.essentials.rest_endpoint
  subject_name      = confluent_schema.banking-info.subject_name
  schema_identifier = confluent_schema.banking-info.schema_identifier
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
}

resource "confluent_schema" "credit-card-info" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.essentials.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.essentials.rest_endpoint
  subject_name  = "CreditCardInfo"
  format        = "AVRO"
  schema        = file("./schemas/avro/creditCardInfo.avsc")
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
}

data "confluent_schema" "credit-card-info" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.essentials.id
  }
  rest_endpoint     = data.confluent_schema_registry_cluster.essentials.rest_endpoint
  subject_name      = confluent_schema.credit-card-info.subject_name
  schema_identifier = confluent_schema.credit-card-info.schema_identifier
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }
}

resource "confluent_schema" "employee-info" {
  hard_delete = true
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.essentials.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.essentials.rest_endpoint
  # https://developer.confluent.io/learn-kafka/schema-registry/schema-subjects/#topicnamestrategy
  subject_name = "employee-value"
  format       = "AVRO"
  schema       = file("./schemas/avro/employee.avsc")

  ruleset {
    domain_rules {
      name = "encrypt"
      kind = "TRANSFORM"
      type = "ENCRYPT"
      mode = "WRITEREAD"

      tags = [confluent_tag.pii.name]
      params = {
        "encrypt.kek.name" = confluent_schema_registry_kek.csfle_key.name,
        "dlq.topic"        = "bad-data"
      }
      on_failure = "DLQ, DLQ"
    }
  }
  schema_reference {
    name         = "credit-card-info"
    subject_name = confluent_schema.credit-card-info.subject_name
    version      = data.confluent_schema.credit-card-info.version
  }
  schema_reference {
    name         = "BankingInfo"
    subject_name = confluent_schema.banking-info.subject_name
    version      = data.confluent_schema.banking-info.version
  }
  credentials {
    key    = confluent_api_key.env-manager-schema-registry-api-key.id
    secret = confluent_api_key.env-manager-schema-registry-api-key.secret
  }

  depends_on = [confluent_tag.pii, confluent_schema.banking-info, confluent_schema.credit-card-info]
}
