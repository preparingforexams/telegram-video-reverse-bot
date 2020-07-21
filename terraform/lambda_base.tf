data "aws_iam_policy_document" "assume_lambda_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name_prefix        = var.bot_name
  assume_role_policy = data.aws_iam_policy_document.assume_lambda_role_policy.json
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:CreateLogGroup"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name_prefix   = "${var.bot_name}_lambda_logging"
  policy = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}


data "aws_iam_policy_document" "invoke_convert" {
  statement {
    actions = ["lambda:InvokeFunction", "lambda:InvokeAsync"]
    resources = [
      aws_lambda_function.convert.arn
    ]
  }
}

resource "aws_iam_role_policy" "invoke_convert" {
  name_prefix = var.bot_name
  role        = aws_iam_role.lambda_role.id

  policy = data.aws_iam_policy_document.invoke_convert.json
}
