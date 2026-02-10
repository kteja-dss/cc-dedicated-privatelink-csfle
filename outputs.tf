output "environment_id" {
  value       = confluent_environment.env.id
  description = "The ID of the Confluent Cloud Environment."
}

output "kafka_cluster_id" {
  value       = confluent_kafka_cluster.dedicated.id
  description = "The ID of the Confluent Cloud Kafka Cluster."
}

output "service_accounts" {
  value = {
    app_manager  = confluent_service_account.app-manager.id
    app_consumer = confluent_service_account.app-consumer.id
    app_producer = confluent_service_account.app-producer.id
  }
  description = "The IDs of the created Service Accounts."
}

# output "resource-ids" {
#   value = <<-EOT
#   Environment ID:   ${confluent_environment.env.id}
#   Kafka Cluster ID: ${confluent_kafka_cluster.dedicated.id}
#
#   Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
#   ${confluent_service_account.app-manager.display_name}:                     ${confluent_service_account.app-manager.id}
#   ${confluent_service_account.app-manager.display_name}'s Kafka API Key:     "${confluent_api_key.app-manager-kafka-api-key.id}"
#   ${confluent_service_account.app-manager.display_name}'s Kafka API Secret:  "${confluent_api_key.app-manager-kafka-api-key.secret}"
#   EOT
#
#   sensitive = true
# }

output "new_policy_debug" {
  value       = data.external.update_kms_policy.result
  sensitive   = true
  description = "Debug output showing the new policy fetched from the Confluent API (via external script)."
}
