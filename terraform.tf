terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  backend "s3" {
    bucket = "devops-pet-tfstate"
    region = "ru-central1"
    key = "terraform.tfstate"

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_region_validation = true
    skip_credentials_validation = true
    skip_s3_checksum = true
    skip_requesting_account_id = true
    use_path_style = true
  }
  required_version = ">= 0.13"
}

