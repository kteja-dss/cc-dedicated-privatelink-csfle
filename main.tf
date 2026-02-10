
# ------------------------------------------------------
# ENVIRONMENT
# ------------------------------------------------------
resource "confluent_environment" "env" {
  display_name = "AWS-PL-CSFLE"

  stream_governance {
    package = "ADVANCED"
  }
}

# # ------------------------------------------------------
# # KAFKA
# # ------------------------------------------------------
data "confluent_schema_registry_cluster" "essentials" {
  environment {
    id = confluent_environment.env.id
  }

  depends_on = [
    confluent_kafka_cluster.dedicated
  ]
}

resource "confluent_network" "private-link" {
  display_name     = "Private Link Network"
  cloud            = "AWS"
  region           = var.region
  connection_types = ["PRIVATELINK"]
  zones            = keys(var.subnets_to_privatelink)
  environment {
    id = confluent_environment.env.id
  }
  dns_config {
    resolution = "PRIVATE"
  }
}

resource "confluent_private_link_access" "aws" {
  display_name = "AWS Private Link Access"
  aws {
    account = var.aws_account_id
  }
  environment {
    id = confluent_environment.env.id
  }
  network {
    id = confluent_network.private-link.id
  }
}

resource "confluent_kafka_cluster" "dedicated" {
  display_name = "inventory"
  availability = "MULTI_ZONE"
  cloud        = confluent_network.private-link.cloud
  region       = confluent_network.private-link.region
  dedicated {
    cku = 2
  }
  environment {
    id = confluent_environment.env.id
  }
  network {
    id = confluent_network.private-link.id
  }
}
####========





// 'app-manager' service account is required in this configuration to create 'orders' topic and assign roles
// to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager-csfle"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.dedicated.rbac_crn
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key-csfle"
  description  = "Kafka API Key that is owned by 'app-manager' service account"

  #   Set optional `disable_wait_for_ready` attribute (defaults to `false`) to `true` if the machine where Terraform is not run within a private network
  disable_wait_for_ready = true

  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = confluent_environment.env.id
    }
  }

  # The goal is to ensure that
  # 1. confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic resource.
  # 2. Kafka connectivity through AWS PrivateLink is setup.
  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin,

    confluent_private_link_access.aws,
    aws_vpc_endpoint.privatelink,
    aws_route53_record.privatelink,
    aws_route53_record.privatelink-zonal,
  ]
}

// Provisioning Kafka Topics requires access to the REST endpoint on the Kafka cluster
// If Terraform is not run from within the private network, this will not work
resource "confluent_kafka_topic" "employee" {
  count = 0
  kafka_cluster {
    id = confluent_kafka_cluster.dedicated.id
  }
  topic_name    = "employee"
  rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_service_account" "app-consumer" {
  display_name = "app-consumer-csfle"
  description  = "Service account to consume from 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_api_key" "app-consumer-kafka-api-key" {
  display_name = "app-consumer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-consumer' service account"

  # Set optional `disable_wait_for_ready` attribute (defaults to `false`) to `true` if the machine where Terraform is not run within a private network
  disable_wait_for_ready = true

  owner {
    id          = confluent_service_account.app-consumer.id
    api_version = confluent_service_account.app-consumer.api_version
    kind        = confluent_service_account.app-consumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = confluent_environment.env.id
    }
  }

  # The goal is to ensure that Kafka connectivity through AWS PrivateLink is setup.
  depends_on = [
    confluent_private_link_access.aws,
    aws_vpc_endpoint.privatelink,
    aws_route53_record.privatelink,
    aws_route53_record.privatelink-zonal,
  ]
}

# resource "confluent_role_binding" "app-producer-developer-write" {
#     count=0
#   principal   = "User:${confluent_service_account.app-producer.id}"
#   role_name   = "DeveloperWrite"
#   crn_pattern = "${confluent_kafka_cluster.dedicated.rbac_crn}/kafka=${confluent_kafka_cluster.dedicated.id}/topic=${confluent_kafka_topic.orders.topic_name}"
# }

resource "confluent_service_account" "app-producer" {
  display_name = "app-producer-csfle"
  description  = "Service account to produce to 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_api_key" "app-producer-kafka-api-key" {

  # Set optional `disable_wait_for_ready` attribute (defaults to `false`) to `true` if the machine where Terraform is not run within a private network
  disable_wait_for_ready = true

  display_name = "app-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-producer' service account"
  owner {
    id          = confluent_service_account.app-producer.id
    api_version = confluent_service_account.app-producer.api_version
    kind        = confluent_service_account.app-producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = confluent_environment.env.id
    }
  }

  # The goal is to ensure that Kafka connectivity through AWS PrivateLink is setup.
  depends_on = [
    confluent_private_link_access.aws,
    aws_vpc_endpoint.privatelink,
    aws_route53_record.privatelink,
    aws_route53_record.privatelink-zonal,
  ]
}

// Note that in order to consume from a topic, the principal of the consumer ('app-consumer' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
# resource "confluent_role_binding" "app-consumer-developer-read-from-topic" {
#     count = 0
#   principal   = "User:${confluent_service_account.app-consumer.id}"
#   role_name   = "DeveloperRead"
#   crn_pattern = "${confluent_kafka_cluster.dedicated.rbac_crn}/kafka=${confluent_kafka_cluster.dedicated.id}/topic=${confluent_kafka_topic.orders.topic_name}"
# }

resource "confluent_role_binding" "app-consumer-developer-read-from-group" {
  principal = "User:${confluent_service_account.app-consumer.id}"
  role_name = "DeveloperRead"
  // The existing value of crn_pattern's suffix (group=confluent_cli_consumer_*) are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update it to match your target consumer group ID.
  crn_pattern = "${confluent_kafka_cluster.dedicated.rbac_crn}/kafka=${confluent_kafka_cluster.dedicated.id}/group=confluent_cli_consumer_*"
}



locals {
  dns_domain = confluent_network.private-link.dns_domain
}
