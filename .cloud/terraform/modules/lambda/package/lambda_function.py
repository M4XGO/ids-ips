import json
import os
import requests

DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")

def lambda_handler(event, context):
    try:
        discord_webhook_url = DISCORD_WEBHOOK_URL
        message = {
            "content": "test"
        }
        
        headers = {
            "Content-Type": "application/json"
        }
        
        response = requests.post(
            discord_webhook_url,
            headers=headers,
            json=message
        )
        
        response.raise_for_status()
        return {
            "statusCode": 200,
            "body": "Message envoyé avec succès!"
        }
        
    except requests.exceptions.RequestException as e:
        return {
            "statusCode": 500,
            "body": str(e)
        }