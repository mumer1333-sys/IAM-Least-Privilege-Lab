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

## Remediation
```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::iam-lab-target-mumer-2026/*"
}
```

## Why This Fix Works
The remediated policy limits the role to exactly two actions — `GetObject` and `PutObject` — instead of every possible S3 action. It also scopes the `Resource` to the specific bucket ARN the role actually needs, with `/*` restricting it further to objects within that bucket rather than the bucket's own configuration or permissions. Even if this Lambda function is fully compromised, an attacker inheriting this role could only read and write objects in one specific bucket — they could not list other buckets, delete this bucket, modify its permissions, or touch any other resource in the account.

## Connection to Production IAM
This mirrors a common mistake in enterprise identity systems like RACF or Active Directory: granting a service account or group broad, catch-all access (e.g., an AD group with modify rights across an entire OU, or a RACF profile covering an entire dataset high-level qualifier) instead of scoping permissions to the exact resource and operation the