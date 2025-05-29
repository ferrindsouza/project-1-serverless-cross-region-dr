#! /usr/bin/bash

# Set variables
PRIMARY_REGION="us-east-1"
SECONDARY_REGION="us-east-2"
ROLE_ARN="*********************************"
PROFILE_NAME="admin"  # Change this to your AWS profile name
TABLE_NAME="HighAvailabilityTable"


# Check if zip is installed, if not install it
if ! command -v zip &> /dev/null; then
    echo "zip command not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y zip
fi

# Package functions into zip files
zip read_function.zip read_function.py
zip write_function.zip write_function.py

# Create ReadFunction in primary region
aws lambda create-function \
  --function-name ReadFunction \
  --runtime python3.9 \
  --role "$ROLE_ARN" \
  --handler read_function.lambda_handler \
  --zip-file fileb://read_function.zip \
  --region "$PRIMARY_REGION" \
  --profile "$PROFILE_NAME" \
  --environment "Variables={TABLE_NAME=$TABLE_NAME,REGION=$PRIMARY_REGION}"

# Create WriteFunction in primary region
aws lambda create-function \
  --function-name WriteFunction \
  --runtime python3.9 \
  --role "$ROLE_ARN" \
  --handler write_function.lambda_handler \
  --zip-file fileb://write_function.zip \
  --region "$PRIMARY_REGION" \
  --profile "$PROFILE_NAME" \
  --environment "Variables={TABLE_NAME=$TABLE_NAME,REGION=$PRIMARY_REGION}"

# Create ReadFunction in secondary region
aws lambda create-function \
  --function-name ReadFunction \
  --runtime python3.9 \
  --role "$ROLE_ARN" \
  --handler read_function.lambda_handler \
  --zip-file fileb://read_function.zip \
  --region "$SECONDARY_REGION" \
  --profile "$PROFILE_NAME" \
  --environment "Variables={TABLE_NAME=$TABLE_NAME,REGION=$SECONDARY_REGION}"

# Create WriteFunction in secondary region
aws lambda create-function \
  --function-name WriteFunction \
  --runtime python3.9 \
  --role "$ROLE_ARN" \
  --handler write_function.lambda_handler \
  --zip-file fileb://write_function.zip \
  --region "$SECONDARY_REGION" \
  --profile "$PROFILE_NAME" \
  --environment "Variables={TABLE_NAME=$TABLE_NAME,REGION=$SECONDARY_REGION}"

echo "Lambda functions deployed to both regions."