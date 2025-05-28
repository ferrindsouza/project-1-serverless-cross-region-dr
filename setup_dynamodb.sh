#! /usr/bin/bash

###########################################################
# Author Ferrin D
# Date 28/05/2025

# Creating a table in DynamoDB through AWS CLI.

# Version v1
###########################################################

# Define Variables
Table_Name="HighAvailabilityTable"
Primary_Region="us-east-1"
Secondary_Region="us-east-2"
Key_Name="ItemId"
Key_Type="S"
Profile_Name="AdminAccess"  # Change this to your AWS profile name

aws dynamodb create-table \
    --table-name $Table_Name \
    --attribute-definitions \
        AttributeName=$Key_Name,AttributeType=$Key_Type \
    --key-schema \
        AttributeName=$Key_Name,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $Primary_Region \
    --profile $Profile_Name \
    --output json \
    --no-cli-pager

echo "Table $Table_Name created in $Primary_Region"

# Enable Global Tables replication from scratch
# aws dynamodb create-global-table \
#     --global-table-name $Table_Name \
#     --replication-group RegionName=$Primary_Region,RegionName=$Secondary_Region \
#     --region $Primary_Region
    
# Update the above table to a global table
aws dynamodb update-table --table-name $Table_Name \
    --replica-updates '[{"Create": {"RegionName": "'$Secondary_Region'"}}]' \
    --region $Primary_Region \
    --profile $Profile_Name \
    --output json \
    --no-cli-pager

echo "Replication enabled for $Table_Name in $Secondary_Region"

# wait for the table to be created in the secondary region
echo "Waiting for the table to be created in $Secondary_Region"
sleep 30

echo "Global table setup finished"