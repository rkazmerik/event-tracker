resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "event_data_bucket" {
  bucket = "${local.project_name}-${random_id.bucket_id.hex}"
  force_destroy = true
  tags = local.common_tags
}

resource "aws_s3_bucket" "athena_query_results" {
  bucket = "athena-query-results-${random_id.bucket_id.hex}"
  force_destroy = true
  tags = local.common_tags
}