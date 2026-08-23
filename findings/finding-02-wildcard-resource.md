# Finding 2: Wildcard Resource IAM Policy

## Severity
High

## MITRE ATT&CK Technique
T1565.001 — Data Manipulation: Stored Data Manipulation

## What It Is
This role's inline policy grants six specific DynamoDB actions — `GetItem`, `PutItem`, `DeleteItem`, `UpdateItem`, `Scan`, and `Query` — which, unlike Finding 1, are individually well-scoped and reasonable for a Lambda function that needs to manage order data. The vulnerability isn't in the actions; it's in the `Resource: "*"` scope, which applies these six actions to every DynamoDB table in the account rather than the single `orders` table the role was intended to use. This is arguably more subtle than Finding 1, since a reviewer skimming the action list alone might conclude the policy is well-designed.

## Misconfigured Configuration
```hcl
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
```

## Attack Scenario
This role is attached to a Lambda function intended to manage order records in a single `orders` table. If that function were compromised, an attacker would inherit the ability to read, write, update, delete, scan, and query every DynamoDB table in the account — not just `orders`. In this lab, that includes a table named `user_credentials`, representative of the kind of sensitive table a real production account might contain. An attacker could exfiltrate an entire credentials table via `Scan`, silently modify records in unrelated tables via `UpdateItem`, or delete data across the account via `DeleteItem` — all using a role that was only ever meant to touch order data.

## Blast Radius
Every DynamoDB table in the AWS account, not just `orders`. This was directly demonstrated in this lab: a proof-of-concept Lambda function using this exact role and policy successfully executed a `Scan` against the `user_credentials` table, despite the role having no documented reason to touch it. See `screenshots/lambda-dynamo-blast-radius-proof.png`.

## Detection
In CloudTrail, this would appear as `dynamodb:Scan`, `dynamodb:Query`, or similar API calls originating from the Lambda execution role's ARN, targeting a `TableName` other than `orders`. A detection rule scoped to this role should flag any DynamoDB API call referencing a table name outside its documented purpose.

## Remediation
```json
{
  "Effect": "Allow",
  "Action": ["dynamodb:GetItem", "dynamodb:UpdateItem"],
  "Resource": "arn:aws:dynamodb:us-east-1:757957162313:table/orders"
}
```

## Why This Fix Works
The remediated policy scopes both the actions and the resource. Actions are reduced from six to two (`GetItem` and `UpdateItem`), matching what an order-processing function actually needs, and the `Resource` is scoped to the specific ARN of the `orders` table rather than every table in the account. Even if this Lambda function is fully compromised, an attacker inheriting this role could only read and update individual order records — they could not scan the entire table, delete records, or touch any other table in the account.

## Connection to Production IAM
This is the DynamoDB equivalent of a common RACF or Active Directory mistake: correctly restricting *what operations* an account can perform (e.g., read-only vs. modify) while forgetting to also restrict *which specific resource* those operations apply to — such as an AD service account with "modify" rights scoped correctly to a permission level, but applied across an entire domain rather than a single OU. Both dimensions — action and resource — need to be scoped together; restricting one without the other leaves a real gap.