output "event_data_bucket_name" {
  description = "Name of the S3 bucket for event data"
  value       = aws_s3_bucket.event_data_bucket.bucket
}

output "athena_query_results_bucket_name" {
  description = "Name of the S3 bucket for Athena query results"
  value       = aws_s3_bucket.athena_query_results.bucket
}

output "firehose_stream_arn" {
  description = "ARN of the Kinesis Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.event_stream.arn
}