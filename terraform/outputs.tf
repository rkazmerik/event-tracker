output "s3_bucket_name" {
  value = aws_s3_bucket.event_data_bucket.bucket
}

output "firehose_stream_name" {
  value = aws_kinesis_firehose_delivery_stream.event_stream.name
}
