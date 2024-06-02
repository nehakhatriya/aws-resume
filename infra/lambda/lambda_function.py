import boto3
import json

db = boto3.resource('dynamodb')
table = db.Table('visitors-count')

def lambda_handler(event, context):
    try:
                response=table.update_item(Key={
                    'id': '1'
                },
                ExpressionAttributeNames={
                '#vc': 'visitor-count'  # Define the placeholder for the attribute name
                },
                UpdateExpression='SET #vc = #vc + :val1',
                ExpressionAttributeValues={
                    ':val1': 1
                },
                ReturnValues='UPDATED_NEW')
                
                count=response['Attributes']['visitor-count']
                
                responseBody= json.dumps({'count':int(count)})
    except:
        putItem = table.put_item(
            Item = {
                'id': '1',
                'visitor-count': 1
            }
        )

        response = table.get_item(
            Key = {
                'id': '1',
            }
        )

        responseBody = json.dumps({"count":int(response['Item']['visitor-count'])})
    apiResponse = {
        "isBase64Encoded": False,
        "statusCode": 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        "body": responseBody
    }

    return apiResponse