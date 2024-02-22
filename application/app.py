import os
import json
import boto3
from flask import Flask, jsonify, request
from botocore.exceptions import ClientError
from decimal import Decimal
import uuid
from boto3.dynamodb.conditions import Key

app = Flask(__name__)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb', region_name='eu-west-1')

# Assuming the DynamoDB table name is set as an environment variable
table_name = os.environ.get('DYNAMODB_TABLE_NAME')
table = dynamodb.Table(table_name)


def convert_floats_to_decimals(obj):
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: convert_floats_to_decimals(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_floats_to_decimals(v) for v in obj]
    return obj


@app.route('/api/hello', methods=['GET'])
def hello_world():
    return jsonify(message="Hello, World!")

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify(status="OK")

@app.route('/api/get/<string:item_id>', methods=['GET'])
def get_data(item_id):
    """
    Retrieve JSON data from DynamoDB by ID.
    """
    try:
        response = table.get_item(Key={'id': item_id})
        if 'Item' in response:
            return jsonify(response['Item'])
        else:
            return jsonify(message="Item not found"), 404
    except ClientError as e:
        return jsonify(error=str(e)), 500
    except Exception as e:
        return jsonify(error=str(e)), 500

@app.route('/api/update/<string:item_id>', methods=['PUT'])
def update_data(item_id):
    """
    Replace the entire JSON data in DynamoDB for a specific ID.
    """
    try:
        # Retrieve the entire new JSON object from the request
        new_data = request.json

        # Ensure the new data is a dictionary and has an 'id' field
        if not isinstance(new_data, dict) or 'id' not in new_data:
            return jsonify(error="Invalid data format: expected a JSON object with an 'id' field"), 400

        # Ensure the 'id' in the new data matches the item_id in the request
        if new_data['id'] != item_id:
            return jsonify(error="Mismatched 'id' in data and URL"), 400

        # Convert all float values to decimals
        new_data = convert_floats_to_decimals(new_data)

        # Replace the entire item in DynamoDB
        table.put_item(Item=new_data)

        return jsonify(message="Item replaced successfully"), 200
    except ClientError as e:
        return jsonify(error=str(e)), 500
    except Exception as e:
        return jsonify(error=str(e)), 500

@app.route('/api/store', methods=['POST'])
def store_data():
    """
    Store JSON data in DynamoDB.
    Expecting JSON data in the request body.
    """
    try:
        data = request.json

        # Extract email from the customer dictionary and add it as a top-level key
        customer_email = data.get('customer', {}).get('email', None)
        if customer_email:
            data['email'] = customer_email

        # Add a UUID as a unique identifier for the item
        uid = str(uuid.uuid4())
        data['id'] = uid

        response = table.put_item(Item=convert_floats_to_decimals(data))
        return jsonify(message="Data stored successfully with ID: " + uid, response=response)
    except ClientError as e:
        return jsonify(error=str(e)), 500
    except Exception as e:
        return jsonify(error=str(e)), 500


@app.route('/api/get-by-email/<string:email>', methods=['GET'])
def get_data_by_email(email):
    """
    Retrieve JSON data from DynamoDB by customer email.
    """
    try:
        response = table.query(
            IndexName='EmailIndex',  # Replace with your GSI name
            KeyConditionExpression=Key('email').eq(email)
        )
        items = response.get('Items', [])
        if items:
            return jsonify(items)
        else:
            return jsonify(message="No items found for the provided email"), 404
    except ClientError as e:
        return jsonify(error=str(e)), 500
    except Exception as e:
        return jsonify(error=str(e)), 500



if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
