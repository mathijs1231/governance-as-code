# Governance as Code for Power Platform and Copilot Studio

Declarative, GitOps-driven provisioning and governance of Power Platform and Copilot Studio with
Azure DevOps YAML pipelines. The desired state lives in YAML in this repository. An idempotent PowerShell 7
module (`GaC.PowerPlatform`) wraps PAC CLI, Power Platform Build Tools and the Power Platform, BAP,
Dataverse and Graph APIs, and reconciles the tenant to that state. Every change runs as **plan → approval →
apply → evidence**.

What it manages:
* Environments, Managed Environments and their settings, environment groups, and self-service sandboxes
* Tenant settings
* DLP policies, connector groups and exceptions, and Advanced Connector Policies
* Security groups, security roles and application users
* Custom connectors
* Solution ALM for Copilot Studio agents across DEV → TEST → ACC → PROD, with connection references,
  environment variables, publishing and smoke/conversation tests
* Drift detection, rollback, auditing and evidence

## Repository structure

| Path | Content |
|---|---|
| [`environments/`](environments) | `_tenant.yaml` + one file per environment; `sandboxes/` for self-service sandboxes |
| [`configuration/`](configuration) | Tenant settings, environment groups, security, deployment-settings templates, JSON schemas |
| [`policies/`](policies) | Managed environment profiles, Advanced Connector Policies, compliance rules |
| [`dlp/`](dlp) | Connector groups, DLP policies, time-boxed exceptions |
| [`connectors/`](connectors) | Custom connector definitions |
| [`agents/`](agents) | Copilot Studio agent manifests and conversation tests |
| [`solutions/`](solutions) | Solution metadata and unpacked solution source |
| [`scripts/`](scripts) | `GaC.PowerPlatform` module, reconcile/validation entry points, bootstrap |
| [`templates/`](templates) | Reusable ADO YAML templates (variables, steps, jobs, stages) |
| [`pipelines/`](pipelines) | Pipeline definitions |
| [`tests/`](tests) | Pester tests (module, configuration, DLP, environments, pipelines) |
| [`docs/`](docs) | Architecture, ADRs, runbooks, onboarding, limitations |

## Pipelines

| Pipeline | File | Trigger | Purpose |
|---|---|---|---|
| gac-pr-validate | [pr-validate.yml](pipelines/pr-validate.yml) | PR build validation | Schema + compliance + Pester + PSScriptAnalyzer; WhatIf plan of the changed scopes |
| gac-platform-provision | [platform-provision.yml](pipelines/platform-provision.yml) | `environments/`, `configuration/`, `policies/managed-environment/`, `connectors/` | Tenant settings, groups, environments, settings, security, connectors, sandboxes, environment groups |
| gac-policy-deploy | [policy-deploy.yml](pipelines/policy-deploy.yml) | `dlp/`, ACP + daily | DLP (with exception expiry) and ACP (API or manual gate) |
| gac-solution-build | [solution-build.yml](pipelines/solution-build.yml) | `solutions/` / manual export | Export from DEV → PR, or version + pack managed + Solution Checker → artifact |
| gac-solution-release | [solution-release.yml](pipelines/solution-release.yml) | Build completion / manual | TEST → ACC → PROD with backup, settings, import, publish, tests |
| gac-drift-detect | [drift-detect.yml](pipelines/drift-detect.yml) | Weekdays 06:00 | Drift report + work item; expired sandbox cleanup |
| gac-env-request | [env-request.yml](pipelines/env-request.yml) | Manual | Self-service sandbox request → PR |
| gac-rollback | [rollback.yml](pipelines/rollback.yml) | Manual | Restore a non-prod environment from backup |

## Quick start

1. Read [docs/architecture.md](docs/architecture.md) and [docs/limitations.md](docs/limitations.md).
2. Adapt `environments/_tenant.yaml`, the DTAP environment files and `templates/variables/*.yml`
   (`keyVaultName`, service connection names).
3. Bootstrap identities, Key Vault and Azure DevOps: [docs/runbooks/bootstrap.md](docs/runbooks/bootstrap.md).
4. Run `gac-platform-provision`, then `gac-policy-deploy`, create the connections
   ([connections.md](docs/runbooks/connections.md)), then build and release a solution
   ([onboarding.md](docs/onboarding.md)).

## Local validation

Requires PowerShell 7.4+.

```powershell
Install-Module powershell-yaml -RequiredVersion 0.4.12 -Scope CurrentUser
Install-Module Pester -MinimumVersion 5.5 -Scope CurrentUser
Install-Module PSScriptAnalyzer -Scope CurrentUser

./scripts/validation/Test-Configuration.ps1                         # schema + compliance (offline)
Invoke-Pester ./tests -Output Detailed                              # unit + repository tests
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings ./PSScriptAnalyzerSettings.psd1

# Plan against a tenant (read-only), after az login + pac auth create:
./scripts/reconcile/Invoke-DlpReconcile.ps1 -WhatIf
./scripts/reconcile/Invoke-EnvironmentReconcile.ps1 -Environment dev -WhatIf
```

## Documentation

* [Architecture](docs/architecture.md) · [Onboarding](docs/onboarding.md) · [Limitations](docs/limitations.md)
* ADRs: [GitOps reconciler](docs/adr/0001-gitops-declarative-reconciler.md) ·
  [Authentication](docs/adr/0002-authentication.md) ·
  [Advanced Connector Policies](docs/adr/0003-advanced-connector-policies.md) ·
  [Key Vault runtime access](docs/adr/0004-key-vault-runtime-access.md)
* Runbooks: [bootstrap](docs/runbooks/bootstrap.md) · [connections](docs/runbooks/connections.md) ·
  [Teams publish](docs/runbooks/teams-publish.md) · [ACP](docs/runbooks/acp.md) · [rollback](docs/runbooks/rollback.md)
