# Finding 4: Unused High-Privilege Access Keys

## Severity
Critical

## MITRE ATT&CK Technique
T1078 — Valid Accounts

## What It Is
`old-admin-user` has the AWS-managed `AdministratorAccess` policy attached — full, unrestricted access to every service and resource in the account — along with a live, active access key. Unlike a role, which grants only temporary credentials, an IAM user's access key remains valid indefinitely until someone manually deactivates or deletes it. This finding was confirmed via the AWS credential report, which showed the key as active but never used since creation, with no MFA enabled on the user.

## Misconfigured Configuration
```hcl
resource "aws_iam_user" "old_admin_user" {
  name = "old-admin-user"
}

resource "aws_iam_user_policy_attachment" "admin_attach" {
  user       = aws_iam_user.old_admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "old_admin_key" {
  user = aws_iam_user.old_admin_user.name
}
```

## Attack Scenario
This represents a common real-world scenario: a key created for a former contractor, a departed employee, or an old automation script that was never rotated or deleted after it was no longer needed. If this key were ever leaked — through a hardcoded value in a GitHub commit, a build log, a misconfigured CI/CD pipeline, or a phishing attack targeting whoever originally had access to it — an attacker would gain immediate, full administrative access to the entire AWS account, with no MFA requirement standing in the way.

## Blast Radius
The entire AWS account. `AdministratorAccess` has no scope restrictions whatsoever — an attacker using this key could create, modify, or delete any resource in any service, exfiltrate data from every S3 bucket and DynamoDB table, provision new infrastructure for cryptomining or further attacks, or even lock the legitimate account owner out entirely by changing IAM policies and passwords.

## Detection
The AWS credential report (`aws iam get-credential-report`) directly surfaces this: the `access_key_1_active` column shows `true` while `access_key_1_last_used_date` shows `N/A`, indicating the key has never been used since creation. See `screenshots/credential-report-unused-keys.png`. In CloudTrail, any actual usage of this key would show as API calls with `old-admin-user` in the `userIdentity` field — the absence of such events, combined with an active key, is itself the finding.

## Remediation
Deactivate and delete the unused access key immediately:
```bash
aws iam update-access-key --access-key-id <KEY_ID> --status Inactive --user-name old-admin-user
aws iam delete-access-key --access-key-id <KEY_ID> --user-name old-admin-user
```
More broadly, remove `AdministratorAccess` entirely if the user has no ongoing legitimate need for it, and if the user must remain active, enforce MFA and scope permissions to only what's actually required.

## Why This Fix Works
An access key that no longer exists cannot be leaked or misused, regardless of where it might have been exposed. Beyond this single key, the underlying fix is process-level: unused credentials should be identified and removed on a regular cadence — for example, via an AWS Config rule flagging any access key unused for 90+ days — rather than relying on someone remembering to clean up manually.

## Connection to Production IAM
This is directly equivalent to the standard practice of deprovisioning accounts in RACF or Active Directory when an employee leaves or a contract ends — an orphaned, still-active AD account or RACF ID with elevated privileges and no recent login activity is one of the most common findings in any access recertification review. The AWS credential report serves the same function as an access certification report in these enterprise systems: surfacing exactly this kind of stale, high-risk credential before an attacker finds it first.