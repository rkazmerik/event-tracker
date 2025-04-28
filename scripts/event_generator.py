import boto3
import json
import random
import time
from datetime import datetime
from faker import Faker

# --- Configuration ---
firehose_stream_name = 'event-delivery-stream'
region_name = 'us-east-2'

# --- Initialize Clients ---
firehose = boto3.client('firehose', region_name=region_name)
faker = Faker()

# --- Sample Pages and Devices ---
pages = ["/home", "/products", "/cart", "/checkout", "/profile", "/about", "/contact"]
devices = ["desktop", "mobile", "tablet"]

# --- Fake Event Generator ---
def generate_fake_event():
    event = {
        "user_id": faker.uuid4(),
        "event_timestamp": datetime.utcnow().isoformat() + "Z",
        "page": random.choice(pages),
        "device": random.choice(devices),
        "browser": faker.user_agent(),
        "ip_address": faker.ipv4_public()
    }
    return event

# --- Main Send Loop ---
for _ in range(10):  # Send 10 events
    event = generate_fake_event()
    print(f"Sending event: {event}")

    response = firehose.put_record(
        DeliveryStreamName=firehose_stream_name,
        Record={
            'Data': json.dumps(event) + "\n"
        }
    )

    print(f"Response: {response['RecordId']}")
    time.sleep(1)
