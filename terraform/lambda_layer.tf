resource "aws_lambda_layer_version" "main" {
  filename   = "../layer.zip"
  layer_name = var.bot_name

  compatible_runtimes = ["python3.8"]
}

data "aws_lambda_layer_version" "ffmpeg" {
  layer_name = "ffmpeg"
}
