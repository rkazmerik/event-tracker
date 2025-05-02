import base64
import hashlib
import json
import uuid
from datetime import datetime, timezone

def lambda_handler(event, context):
    output = []
    for i, record in enumerate(event['records']):
        try:
            payload = base64.b64decode(record['data']).decode('utf-8')
            data = json.loads(payload)

            # Enrich with session id 
            session_key = f"{data['user_id']}_{data['event_timestamp'][:13]}"  # Truncate to hour for session grouping
            data['session_id'] = hashlib.md5(session_key.encode()).hexdigest()

            # Enrich with event id and server ingestion time
            now = datetime.now(timezone.utc)
            data['event_id'] = str(uuid.uuid4())
            data['server_ingestion_time'] = now.strftime('%Y-%m-%dT%H:%M:%SZ')

            if 'event_date' not in data:
                raise ValueError("Missing 'event_date' in event data")

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