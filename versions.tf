# terraform ブロック: この構成を動かすための「道具のバージョン」を宣言する。
# required_version は Terraform CLI 本体、required_providers は AWS 用プラグイン。
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
