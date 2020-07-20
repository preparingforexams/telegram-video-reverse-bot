resource "aws_lambda_function" "convert" {
  function_name = "${var.bot_name}-convert"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.8"
  handler       = "bot.convert"
  timeout       = 900
  memory_size = 1024

  filename         = "../code.zip"
  source_code_hash = filebase64sha256("../code.zip")

  layers = [data.aws_lambda_layer_version.ffmpeg.arn, aws_lambda_layer_version.main.arn]

  environment {
    variables = {
        TELEGRAM_TOKEN = var.telegram_token
    }
  }
}
