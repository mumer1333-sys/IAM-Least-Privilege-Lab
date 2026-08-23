# Finding 1: Wildcard Action IAM Policy

## Severity
High

## MITRE ATT&CK Technique
T1530 — Data from Cloud Storage

## What It Is
This role's inline policy grants `s3:*` — every possible S3 action, including deleting buckets and modifying permissions — scoped to `Resource: "*"`, meaning it applies to every S3 bucket in the AWS account rather than the single bucket the role was intended to use. A policy that should have been scoped to one specific bucket for read/write operations instead grants unrestricted control over every bucket that exists, or ever will exist, in this account.

## Misconfigured Configuration
```hcl
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
```
## Attack Scenario
This role is attached to a Lambda function intended only to read and write objects in a single application bucket. If that Lambda function were compromised — through a vulnerable dependency, a code injection flaw, or a leaked deployment package — an attacker with code execution inside the function would inherit this role's full `s3:*` permissions across every bucket in the account. From there, they could list every bucket's contents, download sensitive data from buckets completely unrelated to this Lambda's actual purpose, exfiltrate logs to cover their tracks, or upload malicious content to buckets used to serve other applications.

## Blast Radius
Every S3 bucket in the AWS account, not just the one this role was intended to use. This was directly demonstrated in this lab: a proof-of-concept Lambda function using this exact role and policy successfully listed every bucket in the account, including a bucket belonging to an entirely separate, unrelated project (`cloud-resume-mumer1333`). See `screenshots/lambda-s3-blast-radius-proof.png`.

## Detection
In CloudTrail, this would appear as `s3:ListBuckets`, `s3:GetObject`, or similar S3 API calls originating from the Lambda execution role's ARN, targeting bucket names outside the function's documented purpose. A well-tuned detection rule would flag any S3 API call from this role referencing a bucket other than the single intended target bucket.