resource "telegram_bot_webhook" "bot" {
  url             = "${cloudflare_record.bot.name}${aws_api_gateway_resource.token.path}"
  allowed_updates = ["message"]
}
