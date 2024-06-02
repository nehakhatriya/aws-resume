data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/lambda/lambda.zip"
}

resource "aws_lambda_function" "lambda_function"{
    filename      = "${path.module}/lambda/lambda.zip"
    function_name = "lambda_function_resume"
    role          = aws_iam_role.iam_for_lambda.arn
    handler       = "lambda_function.lambda_handler"
    runtime       = "python3.8"
    depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "aws_resume_lamnbda_role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


# Retrieve the current AWS region dynamically
data "aws_region" "current" {}

# Retrieve the current AWS account ID dynamically
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
			effect = "Allow"
			actions = [
				"dynamodb:GetItem",
				"dynamodb:PutItem",
				"dynamodb:UpdateItem",
				"dynamodb:DeleteItem"
			]
			resources = ["arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/visitors-count"]
}
}

resource "aws_iam_policy" "policy_for_lambda" {
    name = "database_access"
    path        = "/"
    description = "AWS IAM Policy for aws lambda to access dynamodb"
    policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
    role       = aws_iam_role.iam_for_lambda.name
    policy_arn = aws_iam_policy.policy_for_lambda.arn
}



# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "count_visitor"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "deploy" {
  depends_on=[aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name="stage-01"
}

# resource "aws_api_gateway_stage" "staged" {
#   deployment_id = aws_api_gateway_deployment.deploy.id
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   stage_name    = "stage-01"
# }

resource "aws_api_gateway_resource" "resource" {
  path_part   = "count"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

# Lambda

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# output "base_url" {
#   value = "${aws_api_gateway_stage.staged.invoke_url}/count"
# }