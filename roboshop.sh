#!/bin/bash

# This script dynamically creates multiple EC2 instances using AWS CLI and automatically maps their IP Address to Route53 DNS records.

#To create ec2-instances I have used security group and ami id.
SG_ID="sg-0e0f9f37ba6f57a67"
AMI_ID="ami-0220d79f3f480ecf5"

# To update Route53 DNS records, I have used the Hosted Zone ID.
ZONE_ID="Z0409414C2FUM7G3IGPP"

#Domain name used to map EC2 instance IP addresses.
DOMAIN_NAME="dev88s.online"

# EC2 Creation Loop
# ============================
# Loop through all arguments passed to the script ($@)
# Each argument represents one EC2 instance name

for instance in $@
do
  INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --security-group-ids "$SG_ID" \
  --instance-type "t3.micro" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
  --query 'Instances[0].InstancesId' \
  --output text )

   if [ $instance == "frontend" ]; then
     IP=$(
        aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[].Instances[].PublicIpAddress' \
        --output text
     )  
     RECORD_NAME="$DOMAIN_NAME"  #For public Ip:dev88s.online
   else
      IP=$(
        aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[].Instances[].PrivateIpAddress' \
        --output text
     )
     RECORD_NAME="$instance.$DOMAIN_NAME" #for private IP:mongodb.dev88s.online
   fi
     echo "Ip Address: $IP"

 aws route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --change-batch "{
    \"Changes\": [
      {
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$RECORD_NAME\",
          \"Type\": \"A\",
          \"TTL\": 300,
          \"ResourceRecords\": [
            {\"Value\": \"$IP\"}
          ]
        }
      }
    ]
  }"

 echo "$RECORD_NAME -> $IP created"   
done




