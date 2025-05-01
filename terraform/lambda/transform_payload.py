import json
import base64
import uuid
from datetime import datetime, timezone

def lambda_handler(event, context):
    output = []
    print(f"Received {len(event['records'])} records.")

    for i, record in enumerate(event['records']):
        try:
            # Decode base64-encoded input data
            payload = base64.b64decode(record['data']).decode('utf-8')
            data = json.loads(payload)
            print(f"[Record {i}] Decoded data: {data}")

            # Enrich event with event_id and server_ingestion_time
            now = datetime.now(timezone.utc)
            data['event_id'] = str(uuid.uuid4())
            data['server_ingestion_time'] = now.strftime('%Y-%m-%dT%H:%M:%SZ')

            # Validate event_date presence as it's used for partitioning
            if 'event_date' not in data:
                raise ValueError("Missing 'event_date' in event data")

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
            print(f"[Record {i}] Successfully processed with event_date: {data['event_date']}")

        except Exception as e:
            print(f"[Record {i}] Error processing record: {e}")
            output.append({
                'recordId': record['recordId'],
                'result': 'ProcessingFailed',
                'data': record['data']
            })
    
    print(f"Processed {len(output)} records. Successes: {sum(1 for r in output if r['result'] == 'Ok')}, Failures: {sum(1 for r in output if r['result'] != 'Ok')}")
    return {'records': output}
