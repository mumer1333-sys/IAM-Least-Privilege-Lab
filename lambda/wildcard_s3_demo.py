import boto3
import json

def lambda_handler(event, context):
    s3 = boto3.client('s3')

    # This Lambda's role is only "supposed" to touch iam-lab-target-mumer-2026,
    # but its policy grants s3:* on Resource: "*" — so let's prove it can reach everything.
    response = s3.list_buckets()
    bucket_names = [bucket['Name'] for bucket in response['Buckets']]

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Buckets this role can see (should only be one, but wildcard grants all):',
            'buckets_found': bucket_names
        })
    }