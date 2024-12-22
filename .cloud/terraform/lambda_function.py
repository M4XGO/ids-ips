import json
import os
import requests

DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")

def lambda_handler(event, context):
    if not DISCORD_WEBHOOK_URL:
        raise ValueError("DISCORD_WEBHOOK_URL environment variable is not set")

    # Iterate through CloudWatch Logs events
    for record in event['Records']:
        log_event = record['body']
        message = f"Nouvelle alerte détectée : {log_event}"
        
        # Send a notification to Discord
        payload = {
            "content": message
        }
        response = requests.post(DISCORD_WEBHOOK_URL, json=payload)
        if response.status_code == 204:
            print("Notification envoyée avec succès.")
        else:
            print(f"Erreur d'envoi : {response.status_code}, {response.text}")
    
    return {
        "statusCode": 200,
        "body": json.dumps('Notification envoyée.')
    }