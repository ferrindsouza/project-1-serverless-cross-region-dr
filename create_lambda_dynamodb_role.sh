#! /usr/bin/bash
# This cript creates a role for Lambda to assume to acces DynamoDB

# Set your variables
ROLE_NAME="lambda-dynamodb-role"
POLICY_NAME="DynamoDBAccessPolicy"
TRUST_POLICY_FILE="trust-policy.json"      # Your existing trust policy file
DYNAMODB_POLICY_FILE="dynamodb-policy.json" # Your existing DynamoDB inline policy file
Profile_Name="admin"

# Check if trust policy file exists
if [ ! -f "$TRUST_POLICY_FILE" ]; then
    echo "Trust policy file not found: $TRUST_POLICY_FILE"
    exit 1
fi

# Check if DynamoDB policy file exists
if [ ! -f "$DYNAMODB_POLICY_FILE" ]; then
    echo "DynamoDB policy file not found: $DYNAMODB_POLICY_FILE"
    exit 1
fi

# Create the IAM role
echo "Creating IAM Role: $ROLE_NAME"
aws iam create-role --profile $Profile_Name --role-name "$ROLE_NAME" --assume-role-policy-document "file://$TRUST_POLICY_FILE"

# Attach the DynamoDB inline policy to the role
echo "Attaching DynamoDB inline policy to the role..."
aws iam put-role-policy --profile $Profile_Name --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" --policy-document "file://$DYNAMODB_POLICY_FILE"

#  Attach managed policy for CloudWatch Logs
echo "Attaching CloudWatch Logs managed policy to the role..."
aws iam attach-role-policy --profile $Profile_Name --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

echo "IAM role '$ROLE_NAME' created and configured successfully."