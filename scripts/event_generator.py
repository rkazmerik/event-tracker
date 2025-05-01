import boto3
import json
from faker import Faker
from datetime import datetime, timezone
import random

# --- Configuration ---
firehose_stream_name = 'event-tracking-pipeline-stream'
region_name = 'us-east-2'

# --- Initialize Clients ---
firehose = boto3.client('firehose', region_name=region_name)
faker = Faker()

# --- Initialize Variables ---
browsers = ['Chrome', 'Firefox', 'Safari', 'Edge']
devices = ['Desktop', 'Mobile', 'Tablet']
event_types = ['click', 'view', 'purchase', 'sign-up', 'search', 'error']
pages = ['account','articles','login','promotions','pricing','products','sizzle','settings']
user_ids = [faker.unique.random_int(min=100000, max=999999) for _ in range(100)]

def generate_event():

    event_time = faker.date_time_between(start_date='-1y', end_date='now', tzinfo=timezone.utc)
    
    return {
        'browser': random.choice(browsers),
        'device': random.choice(devices),
        'event_id': faker.uuid4(),
        'event_date': event_time.strftime('%Y-%m-%d'),
        'event_type': random.choice(event_types),
        'event_timestamp': event_time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'ip_address': faker.ipv4(),
        'page': random.choice(pages),
        'user_id': random.choice(user_ids)
    }

def submit_event_to_firehose(event):

    event_json = json.dumps(event)
    print(f"Generating Event:", event['event_id'])

    response = firehose.put_record(
        DeliveryStreamName=firehose_stream_name,
        Record={
            'Data': event_json.encode('utf-8')
        }
    )

    return response

def main():

    num_events = 100000
    for i in range(num_events):
        event = generate_event()
        submit_event_to_firehose(event)

if __name__ == '__main__':
    main()