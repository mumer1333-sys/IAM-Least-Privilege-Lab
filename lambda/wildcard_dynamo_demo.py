import boto3
import json

def lambda_handler(event, context):
    dynamodb = boto3.client('dynamodb')

    # This Lambda's role is only "supposed" to touch the "orders" table,
    # but its policy grants dynamodb actions on Resource: "*" — so let's
    # prove it can reach the "user_credentials" table too.
    response = dynamodb.scan(TableName='user_credentials')

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'This role was only meant to touch "orders", but it can scan "user_credentials" too:',
            'item_count': response['Count'],
            'items': response['Items']
        })
    }