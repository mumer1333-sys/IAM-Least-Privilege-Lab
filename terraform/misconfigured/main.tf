resource "aws_iam_role" "lambda_wildcard_s3" {
  name = "lambda-wildcard-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "wildcard_s3_policy" {
  name = "wildcard-s3-policy"
  role = aws_iam_role.lambda_wildcard_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:*"
      Resource = "*"
    }]
  })
}
resource "aws_s3_bucket" "target_bucket" {
  bucket = "iam-lab-target-mumer-2026"
}

resource "aws_s3_bucket_public_access_block" "target_bucket_block" {
  bucket = aws_s3_bucket.target_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "other_bucket" {
  bucket = "iam-lab-other-mumer-2026"
}

resource "aws_s3_bucket_public_access_block" "other_bucket_block" {
  bucket = aws_s3_bucket.other_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_iam_role" "lambda_wildcard_resource" {
  name = "lambda-wildcard-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "wildcard_resource_policy" {
  name = "wildcard-dynamodb-resource"
  role = aws_iam_role.lambda_wildcard_resource.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ]
      Resource = "*"
    }]
  })
}
resource "aws_dynamodb_table" "orders" {
  name         = "orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "user_credentials" {
  name         = "user_credentials"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
}