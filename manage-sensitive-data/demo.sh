#!/bin/bash
# Manage Sensitive Data POC - Demo Runner

set -euo pipefail

# Default API key
API_KEY="${1:-super-secret-api-key-12345}"

# Function to run the POC comparison
run_poc() {
  echo "======================================================================"
  echo "Terraform Ephemeral Values Demo"
  echo "======================================================================"
  echo "API Key: ${API_KEY:0:10}... (truncated)"
  echo ""

  # Check Terraform version
  echo "Checking Terraform version..."
  TERRAFORM_VERSION=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' || terraform version | head -n1 | cut -d' ' -f2 | tr -d 'v')
  echo "   Terraform version: $TERRAFORM_VERSION"

  MAJOR=$(echo "$TERRAFORM_VERSION" | cut -d. -f1)
  MINOR=$(echo "$TERRAFORM_VERSION" | cut -d. -f2)

  if [ "$MAJOR" -eq 1 ] && [ "$MINOR" -lt 10 ]; then
    echo ""
    echo "WARNING: Terraform 1.10+ required for ephemeral values"
    echo "   Current version: $TERRAFORM_VERSION"
    echo "   The ephemeral example will not work with this version."
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi

  echo ""
  echo "======================================================================"
  echo "Step 1: Testing TRADITIONAL approach (secrets stored in state)"
  echo "======================================================================"
  cd traditional
  terraform init
  terraform apply -auto-approve -var="api_key=$API_KEY"
  cd ..

  echo ""
  echo "======================================================================"
  echo "Step 2: Testing EPHEMERAL approach (secrets NOT in state)"
  echo "======================================================================"
  cd ephemeral
  terraform init
  terraform apply -auto-approve -var="api_key=$API_KEY"
  cd ..

  echo ""
  echo "======================================================================"
  echo "Step 3: Comparing state files"
  echo "======================================================================"
  compare_states

  echo ""
  echo "======================================================================"
  echo "Demo Complete!"
  echo "======================================================================"
  echo ""
  echo "Key Findings:"
  echo "1. Traditional: API key IS stored in state file"
  echo "2. Ephemeral: API key is NOT stored in state file"
  echo ""
  echo "To cleanup:"
  echo "  cd traditional && terraform destroy -auto-approve -var='api_key=$API_KEY'"
  echo "  cd ephemeral && terraform destroy -auto-approve -var='api_key=$API_KEY'"
  echo "======================================================================"
}

# Function to compare state files
compare_states() {
  echo ""
  echo "Analyzing State Files..."
  echo ""

  # Traditional state analysis
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📄 TRADITIONAL State File (traditional/terraform.tfstate)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ -f traditional/terraform.tfstate ]; then
    echo "Looking for 'api_key' in traditional state..."
    if grep -q "api_key" traditional/terraform.tfstate; then
      echo "FOUND: api_key is stored in state file!"
      echo ""
      echo "Triggers in traditional state:"
      jq -r '.resources[] | select(.type=="null_resource") | .instances[0].attributes.triggers' traditional/terraform.tfstate 2>/dev/null || echo "   (Check manually: cat traditional/terraform.tfstate | grep api_key)"
    else
      echo "api_key not found in traditional state"
    fi
  else
    echo "State file not found. Run '$0 run' first"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📄 EPHEMERAL State File (ephemeral/terraform.tfstate)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ -f ephemeral/terraform.tfstate ]; then
    echo "Looking for 'api_key' in ephemeral state..."
    if grep -q "api_key" ephemeral/terraform.tfstate; then
      echo "UNEXPECTED: api_key found in ephemeral state!"
      grep "api_key" ephemeral/terraform.tfstate
    else
      echo "SUCCESS: api_key is NOT in state file (as expected)!"
    fi
  else
    echo "State file not found. Run '$0 run' first"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Traditional approach: Secrets ARE stored in state (security risk)"
  echo "Ephemeral approach:   Secrets are NOT stored in state (secure)"
  echo ""
  echo "Manual inspection:"
  echo "  cat traditional/terraform.tfstate | grep -i api"
  echo "  cat ephemeral/terraform.tfstate | grep -i api"
  echo ""
}

# Function to cleanup resources
cleanup() {
  echo "Cleaning up resources..."
  
  if [ -d traditional ]; then
    echo "Destroying traditional resources..."
    cd traditional
    terraform destroy -auto-approve -var="api_key=$API_KEY" 2>/dev/null || true
    cd ..
  fi
  
  if [ -d ephemeral ]; then
    echo "Destroying ephemeral resources..."
    cd ephemeral
    terraform destroy -auto-approve -var="api_key=$API_KEY" 2>/dev/null || true
    cd ..
  fi
  
  echo "Cleanup complete!"
}

# Function to show usage
usage() {
  cat << EOF
Manage Sensitive Data POC - Demo Runner

Usage: $0 [COMMAND] [API_KEY]

Commands:
  run         Run the full POC demo (default)
  compare     Compare state files only
  cleanup     Destroy all resources
  help        Show this help message

Arguments:
  API_KEY     API key to use for testing (default: super-secret-api-key-12345)

Examples:
  $0                                    # Run full demo with default key
  $0 run my-custom-key                  # Run with custom API key
  $0 compare                            # Only compare existing state files
  $0 cleanup                            # Cleanup all resources

EOF
}

# Main script logic
COMMAND="${1:-run}"

case "$COMMAND" in
  run)
    # If first arg is "run", use second arg as API key
    if [ "$1" = "run" ]; then
      API_KEY="${2:-super-secret-api-key-12345}"
    fi
    run_poc
    ;;
  compare)
    compare_states
    ;;
  cleanup)
    # If first arg is "cleanup", use second arg as API key
    if [ "$1" = "cleanup" ]; then
      API_KEY="${2:-super-secret-api-key-12345}"
    fi
    cleanup
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    # If no recognized command, treat first arg as API key and run
    API_KEY="$1"
    run_poc
    ;;
esac
