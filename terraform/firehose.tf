resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "/aws/kinesisfirehose/${local.project_name}-stream"
  retention_in_days = 90 
  tags              = local.common_tags
}

resource "aws_kinesis_firehose_delivery_stream" "event_stream" {
  name        = "${local.project_name}-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn          = aws_s3_bucket.event_data_bucket.arn
    role_arn            = aws_iam_role.firehose_role.arn
    prefix              = "events/event_date=!{partitionKeyFromLambda:event_date}/"
    buffering_size      = 64
    buffering_interval  = 60
    compression_format  = "GZIP"
    error_output_prefix = "errors/!{firehose:error-output-type}/"

    dynamic_partitioning_configuration {
      enabled = true
    }

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

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = "DeliveryStreamLogs"
    }
  }

  depends_on = [aws_lambda_function.transform_function, aws_cloudwatch_log_group.firehose_log_group]
  tags = local.common_tags
}