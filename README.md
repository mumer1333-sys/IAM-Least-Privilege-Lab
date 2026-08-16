# IAM-Least-Privilege-Lab
A hands on AWS security lab simulating five real-world IAM misconfigurations, audited using native AWS tooling, mapped to MITRE ATT&CK, and remediated to least privilege, built and documented like a consulting style security assessment.

## What This Project Demonstrates

This lab simulates five common IAM misconfigurations found in real AWS environments, wildcard permissions, an overly broad trust policy, an unused admin-level access key, and a privilege escalation path. Each one is deployed intentionally with Terraform, discovered using AWS Access Analyzer and CLI auditing tools (the same way a security engineer would find it in a real account), documented with an attack scenario and MITRE ATT&CK mapping, and then remediated to least privilege.

The goal isn't just to write Terraform, it's to demonstrate the judgment behind real IAM security work: thinking like an attacker, auditing like a defender, and communicating findings like a consultant.

## Project Status

| Phase | Status |
|---|---|
| Environment setup (Terraform, repo structure) | ✅ Complete |
| Misconfigurations 1 & 2 deployed (wildcard S3, wildcard DynamoDB resource) | ✅ Complete |
| Misconfigurations 3, 4, & 5 deployed (broad EC2 trust, unused admin key, privilege escalation) | ✅ Complete |
| Audit phase (Access Analyzer, credential report, CLI investigation) | ✅ Complete |
| Lambda proof-of-concept (blast radius demo) | 🔲 In progress |
| Five finding documents | 🔲 Pending |
| Remediated environment | 🔲 Pending |
| Before/after comparison | 🔲 Pending |

*(This README is being updated as the project progresses — see commit history for the latest.)*

## AWS Services Used

- **IAM** — roles, users, policies, trust policies, permission boundaries, access keys
- **IAM Access Analyzer** — automated external-access auditing
- **S3** — target buckets for the wildcard S3 misconfiguration
- **DynamoDB** — target tables for the wildcard resource misconfiguration
- **Lambda** — proof-of-concept scripts demonstrating exploitable blast radius
- **EC2** — target for the broad trust policy misconfiguration
- **AWS CLI** — used throughout the audit phase alongside the console

## Tools & Languages

- **Terraform (HCL)** — all infrastructure defined as code, in two parallel environments
- **Python 3.12** — Lambda proof-of-concept scripts
- **JSON** — IAM policy documents (before/after for each finding)
- **Markdown** — finding documents and this README
- **Bash** — AWS CLI audit commands

## Repository Structure

IAM-Least-Privilege-Lab/
├── terraform/
│ ├── misconfigured/ ← the five deliberately broken configurations
│ └── remediated/ ← the same environment, fixed to least privilege
├── lambda/ ← Python proof-of-concept scripts
├── findings/ ← five structured security findings
├── screenshots/ ← audit evidence (Access Analyzer, credential report, policy JSON)
└── README.md


## The Five Misconfigurations

| # | Misconfiguration | MITRE ATT&CK |
|---|---|---|
| 1 | Wildcard IAM action (`s3:*` on `Resource: "*"`) | T1530 — Data from Cloud Storage |
| 2 | Wildcard IAM resource (specific DynamoDB actions, `Resource: "*"`) | T1565.001 — Stored Data Manipulation |
| 3 | Overly broad EC2 trust policy | T1078.004 — Valid Accounts: Cloud Accounts |
| 4 | Unused high-privilege access keys | T1078 — Valid Accounts |
| 5 | Missing permission boundary (privilege escalation path) | T1098 — Account Manipulation |

Full technical detail, attack scenarios, and remediation for each finding are documented individually in [`findings/`](./findings).

## Audit Approach

Rather than relying on a single tool, this lab deliberately used multiple layers of auditing:

- **IAM Access Analyzer** (external-access scan) — returned zero findings, since every misconfiguration in this lab is internal over-permissioning rather than external exposure. This is itself a useful finding: automated external-access scanners have real scope limits.
- **AWS Credential Report** — surfaced the unused, active AdministratorAccess key with no MFA enabled (Finding 4).
- **Manual CLI policy review** (`get-role`, `list-role-policies`, `get-role-policy`) — used to independently verify the trust and permission policies for every role, rather than relying on memory of what was written in Terraform.

## Author's Note

This project was built as a hands-on learning exercise in AWS IAM security and Terraform, working through misconfigurations, audit tooling, and remediation one deliberate step at a time. See the commit history for the full build process.

---

**Repo:** you're looking at it.
