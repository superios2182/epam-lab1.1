terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "my-unique-website-bucket-denys-2026" # Имя твоей корзины S3
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"                    # Наша таблица из Шага 1
  }
}

# Настройка провайдера AWS для Jenkins
provider "aws" {
  region = "us-east-1"
}

# Создаем S3 корзину (Bucket). Имя должно быть уникальным во всем мире!
# Если Terraform выдаст ошибку, просто измени цифры в конце имени bucket
resource "aws_s3_bucket" "website" {
  bucket = "my-unique-website-bucket-denys-2026"

  tags = {
    Name        = "Website"
    Environment = "Dev"
  }
}

# Отключаем блокировку публичного доступа для этой корзины (требование для статического сайта)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Настраиваем S3 корзину как хостинг для статического сайта
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

# Создаем политику доступа (Bucket Policy), разрешающую всем читать файлы сайта
resource "aws_s3_bucket_policy" "allow_access" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.allow_access.json

  # Гарантируем, что политика применится только после отключения блокировок доступа
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

data "aws_iam_policy_document" "allow_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.website.arn,
      "${aws_s3_bucket.website.arn}/*",
    ]
  }
}

# Загружаем наш index.html в созданную корзину S3
resource "aws_s3_object" "indexfile" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "./src/index.html"
  content_type = "text/html"
}

# Выводим адрес готового сайта на экран после успешного деплоя
output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.website_config.website_endpoint
}
