provider "aws" {
  region = "us-east-2"
}


# --- S3 RESOURCES ---
resource "aws_s3_bucket" "event_data_bucket" {
  bucket = "event-tracking-pipeline-${random_id.bucket_id.hex}"

  force_destroy = true

  tags = {
    Name = "EventTrackingPipelineBucket"
    Environment = "Dev"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 4
}


# --- IAM RESOURCES ---
resource "aws_iam_role" "firehose_role" {
  name = "firehose_delivery_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "firehose.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "firehose_policy" {
  name        = "firehose_delivery_policy"
  description = "Allow Firehose to put objects into S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:AbortMultipartUpload"
        ],
        Effect   = "Allow",
        Resource = [
          "${aws_s3_bucket.event_data_bucket.arn}",
          "${aws_s3_bucket.event_data_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_role_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}


# --- KINESIS RESOURCES ---
resource "aws_kinesis_firehose_delivery_stream" "event_stream" {
  name        = "event-delivery-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn          = aws_s3_bucket.event_data_bucket.arn
    role_arn            = aws_iam_role.firehose_role.arn
    prefix              = "events/"
    buffering_size      = 1
    buffering_interval  = 30
    compression_format  = "UNCOMPRESSED"
    error_output_prefix = "errors/!{firehose:error-output-type}/"

  }
}





