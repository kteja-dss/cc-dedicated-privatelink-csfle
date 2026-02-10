#!/bin/bash

set -e

eval "$(jq -r '@sh "rest_endpoint=\(.rest_endpoint) key=\(.key) secret=\(.secret) kms_key_id=\(.kms_key_id) aws_access_key=\(.aws_access_key) aws_secret_key=\(.aws_secret_key) aws_region=\(.aws_region)"')"

# Construct the Authorization token
auth_token=$(echo -n "$key:$secret" | base64)


# Fetch the new policy from Confluent Cloud API
new_policy_statement=$(curl -v --location "$rest_endpoint/dek-registry/v1/policy" \
--header "Authorization: Basic $auth_token")


# Extract the new policy
new_statement=$(echo "$new_policy_statement" | jq -r '.policy')

if [[ -z "$new_statement" || "$new_statement" == "null" ]]; then
  echo "Error: Failed to retrieve the new policy from Confluent Cloud."
  exit 1
fi

# Temporarily configure AWS credentials
aws configure set aws_access_key_id "$aws_access_key"
aws configure set aws_secret_access_key "$aws_secret_key"
aws configure set region "$aws_region"

# Fetch the existing KMS key policy
existing_policy=$(aws kms get-key-policy --key-id "$kms_key_id" --policy-name default --query Policy --output text)


if [[ -z "$existing_policy" || "$existing_policy" == "null" ]]; then
  echo "Error: Failed to retrieve the existing KMS key policy."
  exit 1
fi

merged_policy=$(echo "$existing_policy" | jq --argjson new_statement "$new_statement" '.Statement += [$new_statement]')


# Update the KMS key policy
# aws kms put-key-policy --key-id "$kms_key_id" --policy-name default --policy "$merged_policy"

# Return the merged policy
jq -n --arg policy "$merged_policy" '{"policy": $policy}'
