# Finding 5: Missing Permission Boundary (Privilege Escalation Path)

## Severity
Critical

## MITRE ATT&CK Technique
T1098 — Account Manipulation

## What It Is
`developer-role` is granted `iam:CreatePolicy`, `iam:AttachRolePolicy`, and `iam:PutRolePolicy`, scoped to `Resource: "*"`. On the surface, these look like reasonable permissions for a developer who needs to manage IAM resources as part of their work. The actual danger is that nothing prevents the role from creating a new, more permissive policy and attaching it directly to itself — meaning the role's true effective permissions are not fixed by what was originally granted, but by whatever the role chooses to grant itself afterward. This is a privilege escalation path: a role that starts limited can make itself unlimited using its own legitimate-looking permissions as the tool.

## Misconfigured Configuration
```hcl
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
```

## Attack Scenario
A developer, or an attacker who has compromised a session using this role, calls `iam:CreatePolicy` to create a new managed policy granting `AdministratorAccess`-equivalent permissions. They then call `iam:AttachRolePolicy` to attach that new policy directly to `developer-role` — the same role they're currently using. From that point forward, any future session using this role has full administrative access, despite the role's original design intending it to hold only limited, developer-scoped permissions. No external compromise of another account or credential is needed; the escalation happens entirely using permissions the role was already trusted with.

## Blast Radius
The entire AWS account, once the self-escalation is complete. Because the role can grant itself arbitrary new permissions via `PutRolePolicy` or a newly created and attached policy, the practical ceiling on this role's access is effectively unlimited — bounded only by what IAM itself allows, not by what was originally intended.

## Detection
In CloudTrail, look for a role calling `iam:CreatePolicy`, `iam:AttachRolePolicy`, or `iam:PutRolePolicy` targeting *its own* role name — this pattern (a role modifying its own permissions) is a strong signal of privilege escalation and is unusual for legitimate developer workflows, which typically don't involve self-modifying IAM permissions. A detection rule should specifically flag any `AttachRolePolicy` or `PutRolePolicy` call where the target role matches the calling principal's own role.

## Remediation
Attach a permission boundary to the role that caps its maximum possible permissions, regardless of what policies get attached later:
```hcl
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
```

## Why This Fix Works
A permission boundary sets a hard ceiling on what an identity can ever do — the role's *effective* permissions become the intersection of its attached policy and its boundary, never more than the boundary allows. Even if this role successfully creates and attaches a new `AdministratorAccess`-equivalent policy to itself, the boundary still caps its real-world permissions to only S3, DynamoDB, and Lambda actions. The self-escalation attempt technically succeeds at the IAM policy level, but produces no additional real access, because the boundary was never expanded alongside it.

## Connection to Production IAM
This is conceptually similar to scoped delegation limits in Active Directory, where a helpdesk or junior admin account might be delegated the ability to reset passwords or modify group memberships, but is explicitly prevented — via delegation boundaries — from ever being able to grant itself Domain Admin rights, even though it technically has "modify" permissions on directory objects. The lesson is the same in both systems: granting an account the *ability* to modify permissions is not the same as trusting it with *unlimited* permissions, and a boundary or delegation limit is what actually enforces that distinction.