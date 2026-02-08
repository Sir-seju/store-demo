# Secrets Management Architecture

## Overview

We implemented **zero-secret infrastructure** using Azure Key Vault with Workload Identity. Pods authenticate to Azure services without any hardcoded credentials.

## What We Built

```
┌─────────────────────────────────────────────────────────────────┐
│                        THE FLOW                                 │
├─────────────────────────────────────────────────────────────────┤
│  Pod (order-service)                                            │
│       │                                                         │
│       ▼ uses ServiceAccount "order-service"                     │
│  K8s injects OIDC token (via projected volume)                  │
│       │                                                         │
│       ▼ Azure SDK exchanges token with Azure AD                 │
│  Azure AD validates federated credential                        │
│       │                                                         │
│       ▼ Returns Azure access token                              │
│  App calls Key Vault API → Gets secrets                         │
└─────────────────────────────────────────────────────────────────┘
```

## Resources Created

| Resource | Name | Purpose |
|----------|------|---------|
| Key Vault | `kv-devcattle65` | Stores secrets (mongodb-connection, rabbitmq-uri) |
| Managed Identity | `id-devcattle65-workload` | Pods authenticate as this identity |
| Federated Credentials | `order-service`, `product-service` | Links K8s ServiceAccounts to Azure Identity |
| ACR | `acrdevcattle65` | Hosts our custom Docker images |

## Key Files

### Terraform
- `modules/keyvault/` - Key Vault + Workload Identity module
- `main.tf` - Module instantiation with federated credentials

### Kubernetes (Helm)
- `templates/service-accounts.yaml` - ServiceAccounts with `azure.workload.identity/client-id` annotation
- `templates/order-service.yaml` - Uses ServiceAccount + injects `KEY_VAULT_URI` env var
- `values-dev.yaml` - Contains `workloadIdentity.clientId` and `keyVault.uri`

### Application Code
- `src/order-service/plugins/keyvault.js` - SDK helper for fetching secrets
- `src/order-service/package.json` - Added `@azure/keyvault-secrets`

## AWS Equivalent

| Azure | AWS |
|-------|-----|
| Key Vault | Secrets Manager / SSM Parameter Store |
| Workload Identity | IRSA (IAM Roles for Service Accounts) |
| Managed Identity | IAM Role |
| ACR | ECR |

## Usage in Code

```javascript
const { DefaultAzureCredential } = require("@azure/identity")
const { SecretClient } = require("@azure/keyvault-secrets")

const credential = new DefaultAzureCredential()
const client = new SecretClient(process.env.KEY_VAULT_URI, credential)

const secret = await client.getSecret('mongodb-connection')
console.log(secret.value) // The actual connection string
```

---

## Next Steps

### 1. Integrate Key Vault Secrets into Application Logic
- [ ] Wire `keyvault.js` into `messagequeue.js` to fetch RabbitMQ credentials
- [ ] Update `makeline-service` for MongoDB connection from Key Vault
- [ ] Update `product-service` (Rust) with Azure SDK for secrets

### 2. Store Real Secrets in Key Vault
- [ ] Add actual MongoDB connection string to Key Vault
- [ ] Add RabbitMQ credentials to Key Vault
- [ ] Test pods actually fetching and using secrets

### 3. Pipeline Integration
- [ ] Update pipeline to build/push images on code changes
- [ ] Add Terraform plan/apply stage with approval gate
- [ ] Configure environment-specific secrets per stage

### 4. Production Hardening
- [ ] Enable Key Vault network restrictions (private endpoint)
- [ ] Add Key Vault access logging
- [ ] Remove default secrets from Helm charts
- [ ] Set up secret rotation policy
