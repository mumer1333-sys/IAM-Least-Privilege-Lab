resource "aws_iam_role" "lambda_scoped_s3" {
  name = "lambda-scoped-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "scoped_s3_policy" {
  name = "scoped-s3-policy"
  role = aws_iam_role.lambda_scoped_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "${aws_s3_bucket.target_bucket.arn}/*"
    }]
  })
}

resource "aws_s3_bucket" "target_bucket" {
  bucket = "iam-lab-target-mumer-2026-remediated"
}

resource "aws_s3_bucket_public_access_block" "target_bucket_block" {
  bucket = aws_s3_bucket.target_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "lambda_scoped_dynamo" {
  name = "lambda-scoped-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "scoped_dynamo_policy" {
  name = "scoped-dynamodb-policy"
  role = aws_iam_role.lambda_scoped_dynamo.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
      Resource = aws_dynamodb_table.orders.arn
    }]
  })
}

resource "aws_dynamodb_table" "orders" {
  name         = "orders-remediated"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}

resource "aws_iam_role" "scoped_trust_role" {
  name = "scoped-ec2-trust-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:PrincipalTag/Application" = "iam-lab-demo"
        }
      }
    }]
  })
}

resource "aws_iam_instance_profile" "scoped_trust_profile" {
  name = "scoped-ec2-trust-profile"
  role = aws_iam_role.scoped_trust_role.name
}

resource "aws_iam_policy" "developer_boundary" {
  name = "developer-permission-boundary"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:*", "dynamodb:*", "lambda:*"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "developer_role" {
  name                 = "developer-role-remediated"
  permissions_boundary = aws_iam_policy.developer_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.account_id}:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "developer_iam_policy" {
  name = "developer-iam-permissions"
  role = aws_iam_role.developer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:CreatePolicy",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy"
      ]
      Resource = "*"
    }]
  })
}

