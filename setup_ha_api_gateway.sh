#! /usr/bin/bash

###########################################################
# Author Ferrin D
# Date 28/05/2025

# Setting up API and registering it to DNS 
# Note: add the --profile option to make sure it accesses the services through your aws account


# Version v1
###########################################################

set -e

# Variables
PRIMARY_REGION="us-east-1"
SECONDARY_REGION="us-east-2"
API_NAME="HighAvailabilityAPI"
STAGE_NAME="prod"
HOSTED_ZONE_ID="ZXXXXXXXXXXXXX"  # <-- Replace with your Route 53 hosted zone ID
DOMAIN_NAME="api.example.com"

create_api_gateway () {
  REGION=$1
  echo "Creating API in region $REGION..."

  # Create REST API
  API_ID=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --region "$REGION" \
    --query 'id' --output text)

  # Get root resource ID
  PARENT_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query "items[?path=='/'].id" --output text)

  # Create /read and /write resources
  READ_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --parent-id "$PARENT_ID" \
    --path-part "read" \
    --query 'id' --output text)

  WRITE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --parent-id "$PARENT_ID" \
    --path-part "write" \
    --query 'id' --output text)

  # Set GET method for /read linked to ReadFunction
  aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$READ_ID" \
    --region "$REGION" \
    --http-method GET \
    --authorization-type "NONE"

  aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$READ_ID" \
    --region "$REGION" \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$(aws sts get-caller-identity --query Account --output text):function:ReadFunction/invocations"

  # Set POST method for /write linked to WriteFunction
  aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$WRITE_ID" \
    --region "$REGION" \
    --http-method POST \
    --authorization-type "NONE"

  aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$WRITE_ID" \
    --region "$REGION" \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$(aws sts get-caller-identity --query Account --output text):function:WriteFunction/invocations"

  # Deploy API
  aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name "$STAGE_NAME" \
    --region "$REGION"

  echo "API deployed to: https://${API_ID}.execute-api.${REGION}.amazonaws.com/$STAGE_NAME"

  echo $API_ID
}

# Create APIs in both regions
PRIMARY_API_ID=$(create_api_gateway "$PRIMARY_REGION")
SECONDARY_API_ID=$(create_api_gateway "$SECONDARY_REGION")

PRIMARY_URL="${PRIMARY_API_ID}.execute-api.${PRIMARY_REGION}.amazonaws.com/${STAGE_NAME}/read"
SECONDARY_URL="${SECONDARY_API_ID}.execute-api.${SECONDARY_REGION}.amazonaws.com/${STAGE_NAME}/read"

# Create Health Checks
PRIMARY_HC_ID=$(aws route53 create-health-check \
  --caller-reference "$(date +%s)-primary" \
  --health-check-config "Type=HTTPS,ResourcePath=/read,FullyQualifiedDomainName=${PRIMARY_URL},Port=443,RequestInterval=30,FailureThreshold=3" \
  --query 'HealthCheck.Id' --output text)

SECONDARY_HC_ID=$(aws route53 create-health-check \
  --caller-reference "$(date +%s)-secondary" \
  --health-check-config "Type=HTTPS,ResourcePath=/read,FullyQualifiedDomainName=${SECONDARY_URL},Port=443,RequestInterval=30,FailureThreshold=3" \
  --query 'HealthCheck.Id' --output text)

# Create Route 53 Failover Record
aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "{
    \"Changes\": [
      {
        \"Action\": \"CREATE\",
        \"ResourceRecordSet\": {
          \"Name\": \"$DOMAIN_NAME\",
          \"Type\": \"A\",
          \"SetIdentifier\": \"Primary\",
          \"Region\": \"$PRIMARY_REGION\",
          \"Failover\": \"PRIMARY\",
          \"AliasTarget\": {
            \"HostedZoneId\": \"Z1UJRXOUMOOFQ8\",
            \"DNSName\": \"${PRIMARY_API_ID}.execute-api.${PRIMARY_REGION}.amazonaws.com\",
            \"EvaluateTargetHealth\": true
          },
          \"HealthCheckId\": \"$PRIMARY_HC_ID\"
        }
      },
      {
        \"Action\": \"CREATE\",
        \"ResourceRecordSet\": {
          \"Name\": \"$DOMAIN_NAME\",
          \"Type\": \"A\",
          \"SetIdentifier\": \"Secondary\",
          \"Region\": \"$SECONDARY_REGION\",
          \"Failover\": \"SECONDARY\",
          \"AliasTarget\": {
            \"HostedZoneId\": \"Z1UJRXOUMOOFQ8\",
            \"DNSName\": \"${SECONDARY_API_ID}.execute-api.${SECONDARY_REGION}.amazonaws.com\",
            \"EvaluateTargetHealth\": true
          },
          \"HealthCheckId\": \"$SECONDARY_HC_ID\"
        }
      }
    ]
  }"

echo "High availability setup complete! Your API is available at: https://${DOMAIN_NAME}/read"
