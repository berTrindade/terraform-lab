terraform {
  required_version = ">= 1.0"
}

# Traditional sensitive variable - marked sensitive but STILL stored in state
variable "api_key" {
  type        = string
  sensitive   = true
  description = "API key - stored in state file (even though marked sensitive)"
}

provider "null" {}

resource "null_resource" "demo" {
  # Store the API key in triggers - this WILL be in state
  triggers = {
    api_key   = var.api_key # This gets stored in state!
    timestamp = timestamp()
  }

  lifecycle {
    ignore_changes = [triggers["timestamp"]]
  }
}

# Traditional output - stored in state
output "traditional_demo" {
  value     = "API key was stored in state file!"
  sensitive = false
}

# Even with sensitive = true, this value is in the state file
# output "secret_value" {
#   value     = var.api_key
#   sensitive = true
# }
