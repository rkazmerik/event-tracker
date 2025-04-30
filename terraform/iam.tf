resource "aws_iam_role" "firehose_role" {
  name = "${local.project_name}-firehose-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "firehose.amazonaws.com" }
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_policy" "firehose_policy" {
  name        = "${local.project_name}-firehose-policy"
  description = "Allow Firehose to put objects into S3, invoke Lambda, and log to CloudWatch"
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
          aws_s3_bucket.event_data_bucket.arn,
          "${aws_s3_bucket.event_data_bucket.arn}/events/*", 
          "${aws_s3_bucket.event_data_bucket.arn}/errors/*"   
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ],
        Resource = aws_lambda_function.transform_function.arn
      },
      {
        Effect = "Allow",
        Action = ["firehose:EvaluateExpression"],
        Resource = aws_kinesis_firehose_delivery_stream.event_stream.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/${local.project_name}-stream:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_role_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_iam_role" "lambda_role" {
  name = "${local.project_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.project_name}-lambda-policy"
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
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.project_name}-transform-function:*"
      },
      {
        Effect   = "Allow",
        Action   = ["firehose:PutRecord"],
        Resource = aws_kinesis_firehose_delivery_stream.event_stream.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role" "glue_role" {
  name = "${local.project_name}-glue-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_policy" "glue_policy" {
  name = "${local.project_name}-glue-policy"
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
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetPartition",
          "glue:GetPartitions"
        ],
        Resource = [
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:database/events_db",
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:table/events_db/events"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_role_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}
