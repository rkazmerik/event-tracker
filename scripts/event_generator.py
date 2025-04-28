import boto3
import json
import random
from datetime import datetime, timezone
from faker import Faker

# --- Configuration ---
firehose_stream_name = 'event-delivery-stream'
region_name = 'us-east-2'
batch_size = 10  # How many events to send in one batch

# --- Initialize Clients ---
firehose = boto3.client('firehose', region_name=region_name)
faker = Faker()

# --- Sample Pages and Devices ---
pages = ["/home", "/products", "/cart", "/checkout", "/profile", "/about", "/contact"]
devices = ["desktop", "mobile", "tablet"]

# --- Fake Event Generator ---
def generate_fake_event():
    return {
        "user_id": faker.uuid4(),
        "event_timestamp": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z'),
        "page": random.choice(pages),
        "device": random.choice(devices),
        "browser": faker.user_agent(),
        "ip_address": faker.ipv4_public()
    }

# --- Create a Batch of Records ---
records = []

for _ in range(batch_size):
    event = generate_fake_event()
    print(f"Generated event: {event}")
    
    # Each record must end with a newline '\n'
    records.append({
        'Data': json.dumps(event) + "\n"
    })

# --- Send the batch to Firehose ---
response = firehose.put_record_batch(
    DeliveryStreamName=firehose_stream_name,
    Records=records
)

print(f"Batch response: {response}")
