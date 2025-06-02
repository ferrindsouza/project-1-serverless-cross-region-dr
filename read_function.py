# Code for lambda function to read data

import json
import boto3
import os
from decimal import Decimal

#  get region and table name from environment variables with fallbacks
region = os.environ.get('REGION', 'us-east-1')
table_name = os.environ.get('TABLE_NAME', 'HighAvailabilityTable')
dynamodb = boto3.resource('dynamodb', region_name=region)
table = dynamodb.Table(table_name)

def decimal_encoder(obj):
    if isinstance(obj, Decimal):
        if obj % 1 == 0:
            return int(obj)
        else:
            return float(obj)
    raise TypeError(f"Object of type {obj.__class__.__name__} is not JSON serializable")

def lambda_handler(event, context):
    try:
        items = []
        response = table.scan()
        items.extend(response.get('Items', []))

        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            items.extend(response.get('Items', []))
       
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',  # Enable CORS
            },
            'body': json.dumps(items, default=decimal_encoder)  # Return the items array
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',  # Enable CORS
            },
            'body': json.dumps({'error': str(e)})
        }