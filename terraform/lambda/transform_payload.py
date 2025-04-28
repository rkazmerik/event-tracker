import base64
import json
import uuid
from datetime import datetime, timezone

def lambda_handler(event, context):
    output = []

    for record in event['records']:
        # Decode record
        payload = base64.b64decode(record['data'])
        data = json.loads(payload)

        # Enrich
        data['server_ingestion_time'] = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z')
        data['event_id'] = str(uuid.uuid4())

        # Re-encode
        encoded_data = base64.b64encode(json.dumps(data).encode('utf-8')).decode('utf-8')

        output_record = {
            'recordId': record['recordId'],
            'result': 'Ok',
            'data': encoded_data
        }

        output.append(output_record)

    return {'records': output}
