resource "aws_lambda_function" "handle_update" {
  function_name = "${var.bot_name}-handleupdate"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.8"
  handler       = "bot.handle_update"
  timeout       = 30

  filename         = "../code.zip"
  source_code_hash = filebase64sha256("../code.zip")

  layers = [aws_lambda_layer_version.main.arn]

  environment {
    variables = {
        CONVERT_LAMBDA_NAME = aws_lambda_function.convert.function_name
    }
  }
}
