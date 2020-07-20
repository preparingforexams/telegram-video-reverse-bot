data "aws_iam_policy_document" "lambda_role_invoke_policy" {
  statement {
    actions = ["lambda:InvokeFunction", "lambda:InvokeAsync"]
    resources = [
      aws_lambda_function.handle_update.arn
    ]
  }
}

resource "aws_iam_role_policy" "lambda_role_invoke_policy" {
  name_prefix = var.bot_name
  role        = aws_iam_role.lambda_role.id

  policy = data.aws_iam_policy_document.lambda_role_invoke_policy.json
}


resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"

  triggers = {
    redeployment = sha1(join(",", list(
      jsonencode(aws_api_gateway_integration.handle_update)
    )))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.handle_update
  ]
}

resource "aws_api_gateway_base_path_mapping" "api_domain" {
  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = aws_api_gateway_domain_name.domain_name.domain_name
  stage_name  = aws_api_gateway_deployment.deployment.stage_name
}
