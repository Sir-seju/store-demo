# Azure Terraform State Backend Bootstrap

This directory bootstraps the remote state backend for Terraform.

## AWS Equivalent

| AWS | Azure (this) |
|-----|--------------|
| S3 Bucket | Azure Storage Account (Blob) |
| DynamoDB Table (locking) | Built-in Blob Lease (no extra resource!) |
| CloudFormation template | Azure CLI script |

## Usage

```bash
# Make executable
chmod +x setup-state-backend.sh

# Run the bootstrap
./setup-state-backend.sh
```

## What It Creates

1. **Resource Group** (`tfstate-rg`) — container for state resources
2. **Storage Account** — with enterprise security:
   - HTTPS only
   - TLS 1.2 minimum
   - Blob versioning enabled
   - Soft delete (7 days)
   - No public access
3. **Blob Container** (`tfstate`) — stores the `.tfstate` files

## After Running

The script outputs the backend configuration. Add it to your `main.tf` or create a `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "<output-from-script>"
    container_name       = "tfstate"
    key                  = "rosetta.tfstate"
  }
}
```

Then run:
```bash
terraform init
```

Terraform will ask to migrate your local state to the remote backend.

## State Locking

Azure Blob storage uses **native lease locking** — when Terraform runs, it acquires a lease on the state file. If another process tries to run simultaneously, it will fail with a lock error.

No DynamoDB equivalent needed!
