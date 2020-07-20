resource "aws_lambda_permission" "invoke_handle_update" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handle_update.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = replace(base64encode(var.telegram_token), "=", "")
}

resource "aws_api_gateway_method" "handle_update" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "handle_update" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.token.id
  http_method             = aws_api_gateway_method.handle_update.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.handle_update.invoke_arn
}

resource "aws_api_gateway_integration_response" "handle_update" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.handle_update.http_method
  status_code = aws_api_gateway_method_response.handle_update_ok.status_code

  depends_on = [
    aws_api_gateway_integration.handle_update
  ]
}

resource "aws_api_gateway_method_response" "handle_update_ok" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.handle_update.http_method
  status_code = "200"
}
