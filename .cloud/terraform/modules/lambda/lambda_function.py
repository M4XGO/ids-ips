import json
import os
import urllib.request
import logging
import base64
import gzip

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")

def lambda_handler(event, context):
    try:
        logger.info("Event received: %s", event)
        cw_data = event['awslogs']['data']
        compressed_payload = base64.b64decode(cw_data)
        uncompressed_payload = gzip.decompress(compressed_payload)
        log_data = json.loads(uncompressed_payload)
        
        logger.info("Decoded log data: %s", log_data)
        
        # Extraire les événements log
        log_events = log_data['logEvents']
        
        for log_event in log_events:
            log_message = log_event['message']
            lines = log_message.split('\n')
            priority = ""
            attack_type = ""
            from_ip = ""
            to_ip = ""

            for line in lines:
                if "Priority:" in line:
                    priority = line.split("Priority:")[1].split("]")[0].strip()
                if "{TCP}" in line:
                    from_ip = line.split("{TCP}")[1].split("->")[0].strip()
                    to_ip = line.split("->")[1].strip()
                if "[**]" in line:
                    attack_type = line.split("[**]")[1].split("]")[1].strip()

            formatted_message = f"Priority: **{priority}** :boom: \nType d'attaque: **{attack_type}**\nFrom: **{from_ip}**\nTo: **{to_ip}**"
            message = {
                "content": f"## :warning: Alerte Suricata! :warning: \n \n{formatted_message}\n"
            }
            
            data = json.dumps(message).encode('utf-8')
            req = urllib.request.Request(
                DISCORD_WEBHOOK_URL,
                data=data,
                headers={
                    'Content-Type': 'application/json',
                    'User-Agent': 'Python/3.8'
                },
                method='POST'
            )
            
            with urllib.request.urlopen(req) as response:
                logger.info("Message envoyé: %d", response.status)
        
        return {
            "statusCode": 200,
            "body": "Messages envoyés avec succès!"
        }
            
    except Exception as e:
        logger.error("Error: %s", e)
        return {
            "statusCode": 500,
            "body": str(e)
        }