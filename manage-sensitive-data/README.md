# Terraform Ephemeral Values Demo

Simple demonstration of **ephemeral values** (Terraform 1.10+) vs traditional sensitive variables.

← [Back to Workspace](../README.md)

## What This Shows

Ephemeral values prevent secrets from being stored in Terraform state files.

## Structure

```
manage-sensitive-data/
├── ephemeral/      # Modern: ephemeral = true (secrets NOT in state)
├── traditional/    # Old: sensitive = true (secrets IN state)
└── demo.sh         # Run demos, compare states, or cleanup
```

## The Difference

**Traditional** (`sensitive = true`) - Terraform 1.0+
- Secret stored in state file (plaintext)
- Masked in console output
- Must secure state file

**Ephemeral** (`ephemeral = true`) - **Terraform 1.10+**
- Secret NEVER in state
- Masked in console output
- Secure by design

## Quick Start

```bash
# Run the complete demo
./demo.sh

# Or test manually
cd traditional
terraform init
terraform apply -var="api_key=my-secret"
grep "my-secret" terraform.tfstate  # Found!

cd ../ephemeral  
terraform init
terraform apply -var="api_key=my-secret"
grep "my-secret" terraform.tfstate  # Not found!
```

## Compare Results

```bash
./demo.sh compare

# Or manually inspect
cat traditional/terraform.tfstate   # Contains secrets
cat ephemeral/terraform.tfstate     # Clean!
```

## Use Cases

- API keys & tokens
- Database passwords  
- Certificates & private keys
- Temporary credentials
- Any secret that shouldn't persist

## Production Usage

**This POC shows the feature. For production password management:**

1. **Best:** AWS RDS with `manage_master_user_password = true` (AWS generates, stores in Secrets Manager)
2. **Good:** Reference existing Secrets Manager secret + ephemeral for initial setup
3. **Avoid:** Generating passwords with Terraform (even with ephemeral, manage carefully)

**Key principle:** Terraform manages infrastructure, Secrets Manager stores runtime secrets.

## Requirements

- **Terraform >= 1.10** (ephemeral values introduced in v1.10)
- **Terraform >= 1.0** (traditional example)

> **Note:** Ephemeral values (`ephemeral = true`) were introduced in Terraform 1.10. All previous versions (1.9.x and earlier) do not support this feature and will store sensitive values in state even when marked `sensitive = true`.

## Learn More

- [Terraform Docs: Sensitive Data](https://developer.hashicorp.com/terraform/language/state/sensitive-data)
- [Terraform v1.9.x: No Ephemeral Support](https://developer.hashicorp.com/terraform/language/v1.9.x/state/sensitive-data)
- [Ephemeral Values Guide](https://developer.hashicorp.com/terraform/language/values/variables#ephemeral)
