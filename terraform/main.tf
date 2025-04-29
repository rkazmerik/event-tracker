provider "aws" {
  region = "us-east-2"
}

# --- RANDOM ID FOR S3 BUCKET ---
resource "random_id" "bucket_id" {
  byte_length = 4
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

resource "aws_s3_bucket" "athena_query_results" {
  bucket = "athena-query-results-${random_id.bucket_id.hex}"

  force_destroy = true
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
  description = "Allow Firehose to put objects into S3 bucket and invoke Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:AbortMultipartUpload"
        ],
        Resource = [
          "${aws_s3_bucket.event_data_bucket.arn}",
          "${aws_s3_bucket.event_data_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_role_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_iam_role" "lambda_role" {
  name = "firehose_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "firehose_lambda_policy"
  description = "Allow Lambda to write logs and send records to Firehose"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "firehose:PutRecord",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role" "glue_role" {
  name = "glue_crawler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "glue_policy" {
  name = "glue_crawler_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.event_data_bucket.arn,
          "${aws_s3_bucket.event_data_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "glue:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_role_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}


# --- LAMBDA RESOURCES ---
resource "aws_lambda_function" "transform_function" {
  filename         = "./lambda/transform_payload.zip"
  function_name    = "firehose_transform_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "transform_payload.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("./lambda/transform_payload.zip")
  timeout       = 60
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
    compression_format  = "GZIP"
    error_output_prefix = "errors/!{firehose:error-output-type}/"

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = aws_lambda_function.transform_function.arn
        }
      }
    }
  }

  depends_on = [aws_lambda_function.transform_function]
}

# --- GLUE RESOURCES ---
resource "aws_glue_catalog_database" "events_db" {
  name = "events_db"
}

resource "aws_glue_catalog_table" "events_table" {
  name          = "events"
  database_name = aws_glue_catalog_database.events_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"  = "json"
    "compressionType"  = "gzip"
    "typeOfData"       = "file"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.event_data_bucket.bucket}/events/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed    = true

    ser_de_info {
      name                  = "json"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "browser"
      type = "string"
    }

    columns {
      name = "device"
      type = "string"
    }

    columns {
      name = "event_id"
      type = "string"
    }

    columns {
      name = "event_type"
      type = "string"
    }

    columns {
      name = "event_timestamp"
      type = "timestamp"
    }

    columns {
      name = "ip_address"
      type = "string"
    }

    columns {
      name = "page"
      type = "string"
    }

    columns {
      name = "server_ingestion_time"
      type = "timestamp"
    }

    columns {
      name = "user_id"
      type = "string"
    }

  }
}

# --- ATHENA RESOURCES ---
resource "aws_athena_workgroup" "event_queries" {
  name = "event_queries"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results.bucket}/results/"
    }
  }
}



