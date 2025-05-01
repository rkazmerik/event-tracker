resource "aws_lambda_function" "transform_function" {
  filename         = "./lambda/transform_payload.zip"
  function_name    = "${local.project_name}-transform-function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "transform_payload.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("./lambda/transform_payload.zip")
  timeout          = 60
  tags             = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.transform_function.function_name}"
  retention_in_days = 90
  tags              = local.common_tags
}