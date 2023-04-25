terraform {
  required_version = "1.4.5"

  backend "remote" {
    hostname = "app.terraform.io"

    workspaces {
      name = "reversebot"
    }
  }

  required_providers {
    telegram = {
      source  = "yi-jiayu/telegram"
      version = "0.3.1"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 2.0"
    }
  }
}

variable "cloudflare_token" {}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

variable "aws_region" {
  default = "eu-central-1"
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

provider "telegram" {
  # You'll need to install https://github.com/yi-jiayu/terraform-provider-telegram
  bot_token = var.telegram_token
}
