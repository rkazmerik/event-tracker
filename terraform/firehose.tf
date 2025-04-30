resource "aws_kinesis_firehose_delivery_stream" "event_stream" {
  name        = "${local.project_name}-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn          = aws_s3_bucket.event_data_bucket.arn
    role_arn            = aws_iam_role.firehose_role.arn
    prefix              = "events/"
    buffering_size      = 64
    buffering_interval  = 10
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

  tags = local.common_tags
}