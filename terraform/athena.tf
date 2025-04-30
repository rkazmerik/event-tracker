resource "aws_athena_workgroup" "event_queries" {
  name = "${local.project_name}-queries"
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results.bucket}/results/"
    }
  }
  tags = local.common_tags
}