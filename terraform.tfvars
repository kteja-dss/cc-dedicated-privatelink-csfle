
# The AWS account ID to enable for the Private Link Access.
# You can find your AWS account ID here (https://console.aws.amazon.com/billing/home?#/account) under My Account section of the AWS Management Console. Must be a 12 character string.
aws_account_id = "829250931565"

# The VPC ID that you want to connect to Confluent Cloud Cluster
# https://us-east-1.console.aws.amazon.com/vpc/home?region=us-east-1#vpcs:
# DNS hostnames and DNS resolution should be enabled:
# * Your VPC -> Actions -> Edit DNS hostnames
# * Your VPC -> Actions -> Edit DNS resolution
vpc_id = "vpc-070fb5102c45b5a21"

# aws ec2 create-vpc-endpoint --vpc-id vpc-070fb5102c45b5a21 \
#   --service-name com.amazonaws.vpce.us-east-2.vpce-svc-013e133da40f09f35 \
#   --subnet-ids <subnet IDs for the endpoint> \
#   --region us-east-2 subnet-05d831319828cbc12 subnet-04eabafac020dabca subnet-01e896b520ff6bc15 \
#   --private-dns-enabled false \
#   --vpc-endpoint-type Interface

# The region of your VPC that you want to connect to Confluent Cloud Cluster
# Cross-region AWS PrivateLink connections are not supported yet.
region = "us-east-2"

# The map of Zone ID to Subnet ID. You can find subnets to private link mapping information by clicking at VPC -> Subnets from your AWS Management Console (https://console.aws.amazon.com/vpc/home)
# https://us-west-1.console.aws.amazon.com/vpc/home?region=us-east-1#subnets:search=vpc-abcdef0123456789a
# You must have subnets in your VPC for these zones so that IP addresses can be allocated from them.
subnets_to_privatelink = {
  "use2-az1" = "subnet-05d831319828cbc12",
  "use2-az2" = "subnet-04eabafac020dabca",
  "use2-az3" = "subnet-01e896b520ff6bc15"
}


aws_kms_key_id = "arn:aws:kms:us-east-2:829250931565:key/0ed73530-a492-4e96-84fe-46f0080b576a"
















confluent_cloud_api_key = "RFYYUGXWCPOFVVLJ"

confluent_cloud_api_secret = "IK5ilSNwLbgM2FSOk1ILOagScp/357ZABrMbtoX0A0ojksvSo/OwF4tJZ5jf8nlb"

aws_key = "AKIA4CEZVBNWYE5NJYMR"

aws_secret = "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"


