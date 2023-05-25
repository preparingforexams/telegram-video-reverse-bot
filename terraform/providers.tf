terraform {
  required_version = "1.4.5"

  backend "s3" {
    bucket = "legacy-terraform-states"
    key = "videoreverse"
    region = "eu-central-1"
  }

  required_providers {
    telegram = {
      source  = "yi-jiayu/telegram"
      version = "0.3.1"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

variable "cloudflare_token" {}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

provider "aws" {
  region  = "eu-central-1"
}

provider "telegram" {
  bot_token = var.telegram_token
}
