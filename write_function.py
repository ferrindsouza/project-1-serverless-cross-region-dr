import json
import boto3
import os

# Get region and table name from environment variables with fallbacks
region = os.environ.get('REGION', 'us-east-1')
table_name = os.environ.get('TABLE_NAME', 'HighAvailabilityTable')

# Initialize DynamoDB resource with explicit region
dynamodb = boto3.resource('dynamodb', region_name=region)
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    try:
        # Check if body exists
        if 'body' not in event or not event['body']:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Missing request body'})
            }
            
        body = json.loads(event['body'])
        
        # Validate required fields
        if 'ItemId' not in body or 'Data' not in body:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Missing required fields: ItemId and Data'})
            }
            
        item_id = body['ItemId']
        data = body['Data']

        # Write to DynamoDB
        table.put_item(Item={'ItemId': item_id, 'Data': data})
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Item saved successfully'})
        }
    except Exception as e:
        print(f"Error: {str(e)}")  # Log the error for CloudWatch
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }