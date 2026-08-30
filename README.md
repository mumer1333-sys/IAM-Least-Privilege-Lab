# IAM Least Privilege Break-and-Fix Lab

A hands-on AWS security lab simulating five real-world IAM misconfigurations, audited using native AWS tooling, mapped to MITRE ATT&CK, and remediated to least privilege — built and documented like a consulting-style security assessment.

## What This Project Demonstrates

This lab simulates five common IAM misconfigurations found in real AWS environments — wildcard permissions, an overly broad trust policy, an unused admin-level access key, and a privilege escalation path. Each one was deployed intentionally with Terraform, discovered using AWS Access Analyzer and CLI auditing tools the same way a security engineer would find it in a real account, documented with an attack scenario and MITRE ATT&CK mapping, proven exploitable with working Lambda proof-of-concept code, and then remediated to least privilege with before/after evidence.

The goal isn't just to write Terraform — it's to demonstrate the judgment behind real IAM security work: thinking like an attacker, auditing like a defender, and communicating findings like a consultant.

## Project Status

| Phase | Status |
|---|---|
| Environment setup (Terraform, repo structure) | ✅ Complete |
| Misconfigurations 1–5 deployed | ✅ Complete |
| Audit phase (Access Analyzer, credential report, CLI investigation) | ✅ Complete |
| Lambda proof-of-concept (blast radius demonstrated) | ✅ Complete |
| Five finding documents | ✅ Complete |
| Remediated environment deployed | ✅ Complete |
| Before/after audit comparison | ✅ Complete |

**Project complete.** All five misconfigurations were built, audited, exploited via proof-of-concept, documented, and remediated with verified evidence.

## Before / After

| | Misconfigured Environment | Remediated Environment |
|---|---|---|
| **IAM roles** | 4 roles, all overly permissive | 4 roles, all scoped to least privilege |
| **S3 policy** | `s3:*` on `Resource: "*"` | `GetObject`, `PutObject` scoped to one bucket ARN |
| **DynamoDB policy** | 6 actions on `Resource: "*"` | `GetItem`, `UpdateItem` scoped to one table ARN |
| **EC2 trust policy** | Any EC2 instance in the account could assume the role | Restricted via `Condition` to instances tagged `Application = iam-lab-demo` |
| **Admin access key** | Active, AdministratorAccess, never used, no MFA | Deleted entirely |
| **Developer role** | Could self-escalate to admin via IAM policy creation | Same IAM-editing permissions, capped by a permission boundary limiting real access to S3/DynamoDB/Lambda only |
| **Total resources** | 20 (misconfigured) | 12 (remediated) |

Every fix in this table is independently verified via AWS CLI, not just asserted from the Terraform code — see `screenshots/` for the `before-*` and `after-*` evidence pairs referenced in each finding document.

## AWS Services Used

- **IAM** — roles, users, policies, trust policies, permission boundaries, access keys
- **IAM Access Analyzer** — automated external-access auditing
- **S3** — target buckets for the wildcard S3 misconfiguration and its fix
- **DynamoDB** — target tables for the wildcard resource misconfiguration and its fix
- **Lambda** — proof-of-concept scripts demonstrating exploitable blast radius
- **EC2** — target for the broad trust policy misconfiguration and its fix
- **AWS CLI** — used throughout both the audit and verification phases

## Tools & Languages

- **Terraform (HCL)** — all infrastructure defined as code, in two parallel environments
- **Python 3.12** — Lambda proof-of-concept scripts (boto3)
- **JSON** — IAM policy documents (before/after for each finding)
- **Markdown** — finding documents and this README
- **Bash** — AWS CLI audit and verification commands

## Repository Structure

```
IAM-Least-Privilege-Lab/
├── terraform/
│   ├── misconfigured/     (the five deliberately broken configurations — since destroyed)
│   └── remediated/        (the same environment, fixed to least privilege)
├── lambda/                (Python proof-of-concept scripts)
├── findings/              (five structured security findings)
├── screenshots/           (audit evidence: Access Analyzer, credential report, before/after policy JSON)
└── README.md
```

## The Five Misconfigurations

| # | Misconfiguration | Severity | MITRE ATT&CK |
|---|---|---|---|
| 1 | Wildcard IAM action (`s3:*` on `Resource: "*"`) | High | T1530 — Data from Cloud Storage |
| 2 | Wildcard IAM resource (specific DynamoDB actions, `Resource: "*"`) | High | T1565.001 — Stored Data Manipulation |
| 3 | Overly broad EC2 trust policy | Medium | T1078.004 — Valid Accounts: Cloud Accounts |
| 4 | Unused high-privilege access keys | Critical | T1078 — Valid Accounts |
| 5 | Missing permission boundary (privilege escalation path) | Critical | T1098 — Account Manipulation |

Full technical detail, attack scenarios, blast radius evidence, and remediation for each finding are documented individually in [`findings/`](./findings).

## Audit Approach

Rather than relying on a single tool, this lab deliberately used multiple layers of auditing:

- **IAM Access Analyzer** (external-access scan) — returned zero findings both before and after remediation, since every misconfiguration in this lab was internal over-permissioning rather than external exposure. This is itself a useful finding: automated external-access scanners have real scope limits, and a thorough audit needs more than one tool.
- **AWS Credential Report** — surfaced the unused, active AdministratorAccess key with no MFA enabled before remediation (Finding 4), and confirmed its complete removal afterward.
- **Manual CLI policy review** (`get-role`, `list-role-policies`, `get-role-policy`) — used to independently verify the trust and permission policies for every role both before and after the fix, rather than relying on the Terraform source alone.
- **Lambda proof-of-concept** — two working Lambda functions, deployed using the actual misconfigured roles, demonstrated real exploitation rather than theoretical risk. The S3 wildcard role successfully listed every bucket in the account, including one from a completely unrelated project; the DynamoDB wildcard role successfully scanned a table outside its intended scope.

## Author's Note

This project was built as a hands-on learning exercise in AWS IAM security and Terraform, working through misconfigurations, audit tooling, exploitation, and remediation one deliberate step at a time. See the commit history for the full build process, including real debugging along the way (a free-tier instance type mismatch, a `.gitignore` gap, and a duplicate Terraform resource block — all caught and fixed as part of the process).

---

**Repo:** you're looking at it.