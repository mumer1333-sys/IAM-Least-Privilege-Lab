# Finding 3: Overly Broad Trust Policy

## Severity
Medium

## MITRE ATT&CK Technique
T1078.004 — Valid Accounts: Cloud Accounts

## What It Is
This role's trust policy allows any EC2 instance in the account to assume it — the `Principal` is set to the entire `ec2.amazonaws.com` service, with no condition restricting which specific instance, tag, or source is permitted. This is a different category of misconfiguration from Findings 1 and 2: those were about *what* a role can do once assumed, while this is about *who* can assume the role in the first place. A role can have perfectly scoped permissions and still be dangerous if the wrong entity can take it on.

## Misconfigured Configuration
```hcl
resource "aws_iam_role" "broad_trust_role" {
  name = "broad-ec2-trust-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
```

## Attack Scenario
Every EC2 instance can reach an internal, unauthenticated metadata endpoint (`169.254.169.254`) that hands out temporary credentials for whatever IAM role is attached to it via an instance profile. If an attacker compromises *any* EC2 instance in the account — through a vulnerable web application, an exposed SSH key, or a server-side request forgery (SSRF) vulnerability — and that instance happens to have this role's instance profile attached, the attacker can query the metadata endpoint from inside the instance and walk away with valid, usable credentials. Because the trust policy doesn't restrict *which* instance can assume the role, this risk isn't limited to the instance the role was designed for.

## Blast Radius
Any workload running on the EC2 instance this role is attached to, plus anything that instance's other permissions allow it to reach. In this lab, that includes the `broad-trust-demo-instance` created alongside this role. In a production account with multiple EC2 instances and instance profiles, the practical risk scales with how many instances exist and how permissive their attached roles are.

## Detection
In CloudTrail, look for `sts:AssumeRole` events where the `Principal` type is `ec2.amazonaws.com`, cross-referenced against which specific EC2 instance actually requested the credentials (visible in the `userIdentity` and `sourceIPAddress` fields). Any assumption from an instance outside the expected, documented set is worth investigating.

## Remediation
Restrict which instances can assume the role using condition keys on the trust policy — for example, requiring a specific instance tag or source VPC — rather than trusting the entire `ec2.amazonaws.com` service unconditionally. In practice, this means adding a `Condition` block to the trust policy that checks something like `aws:SourceVpc` or a tag-based condition, so only instances matching that specific criteria can successfully call `sts:AssumeRole`.

## Why This Fix Works
Even though the permission policy attached to this role may be appropriately scoped, an unrestricted trust policy means *any* EC2 instance — including ones never intended to use this role — could potentially assume it if attached. Adding a condition narrows the trust policy from "any EC2 instance in existence" to "only EC2 instances matching this specific, documented criteria," closing the gap between intended use and actual permitted use.

## Connection to Production IAM
This mirrors the concept of trusted subnets or source restrictions in Active Directory and RACF environments — for example, restricting which workstations or servers a service account can log in from, rather than allowing the account to authenticate from anywhere on the network. A permission set can be perfectly scoped and still represent unacceptable risk if the *origin* of the request isn't also restricted.