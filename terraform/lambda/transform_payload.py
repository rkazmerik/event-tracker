import json
import base64
import uuid
from datetime import datetime, timezone

def lambda_handler(event, context):
    output = []
    
    for record in event['records']:
        try:
            # Decode base64-encoded input data
            payload = base64.b64decode(record['data']).decode('utf-8')
            data = json.loads(payload)
            
            # Enrich event with event_id and server_ingestion_time
            now = datetime.now(timezone.utc)
            data['event_id'] = str(uuid.uuid4())
            data['server_ingestion_time'] = now.strftime('%Y-%m-%dT%H:%M:%SZ')

            # Encode transformed data back to base64 with newline added
            transformed_payload = json.dumps(data) + "\n"
            encoded_data = base64.b64encode(transformed_payload.encode('utf-8')).decode('utf-8')

            output.append({
                'recordId': record['recordId'],
                'result': 'Ok',
                'data': encoded_data,
                'metadata': {
                    'partitionKeys': {
                        'event_date': data['event_date']
                    }
                }
            })

        except Exception as e:
            output.append({
                'recordId': record['recordId'],
                'result': 'ProcessingFailed',
                'data': record['data']
            })
    
    return {'records': output}
