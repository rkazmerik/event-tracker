import boto3
import json
from faker import Faker
from datetime import datetime, timezone
import random

# --- Configuration ---
firehose_stream_name = 'event-delivery-stream'
region_name = 'us-east-2'

# --- Initialize Clients ---
firehose = boto3.client('firehose', region_name=region_name)
faker = Faker()

def generate_event():

    return {
        'browser': random.choice(['Chrome', 'Firefox', 'Safari', 'Edge']),
        'device': random.choice(['Desktop', 'Mobile', 'Tablet']),
        'event_id': faker.uuid4(),
        'event_type': random.choice(['click', 'view', 'purchase', 'login']),
        'event_timestamp': faker.date_time_between(start_date='-1y', end_date='now', tzinfo=timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z'),
        'ip_address': faker.ipv4(),
        'page': faker.uri_path(),
        'server_ingestion_time': datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z'),
        'user_id': faker.uuid4()
    }

def submit_event_to_firehose(event):

    event_json = json.dumps(event)
    print(f"Generating Event:", event_json)

    response = firehose.put_record(
        DeliveryStreamName=firehose_stream_name,
        Record={
            'Data': event_json.encode('utf-8')
        }
    )

    print(f"Response Code: {response['ResponseMetadata']['HTTPStatusCode']}", end="\n\n")
    return response

def main():

    num_events = 10
    for i in range(num_events):
        event = generate_event()
        submit_event_to_firehose(event)

if __name__ == '__main__':
    main()