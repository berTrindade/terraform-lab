terraform {
  required_version = ">= 1.10"
}

# Ephemeral input variable - value never stored in state
variable "api_key" {
  type        = string
  sensitive   = true # Hides in CLI
  ephemeral   = true # Omits from state 
  description = "API key - never stored in state file"
}

# Provider using ephemeral value
# The API key is used but never persisted
provider "null" {}

resource "null_resource" "demo" {
  # Using ephemeral value in provisioner (ephemeral values CAN be used here)
  provisioner "local-exec" {
    command = "echo 'Using ephemeral API key...'"
    environment = {
      # Ephemeral value can be used in provisioner
      # Won't be stored in state
      API_KEY = var.api_key
    }
  }

  triggers = {
    # Cannot use ephemeral value in triggers (persisted to state)
    # api_key = var.api_key  # This would error!

    # Only non-ephemeral values in triggers
    timestamp = timestamp()
  }
}

# Ephemeral output - can be used within the same run but not stored
output "ephemeral_demo" {
  value     = "API key was used but is not in state!"
  ephemeral = false
}

# This would be ephemeral output - not stored in state
# output "secret_value" {
#   value     = var.api_key
#   ephemeral = true
#   sensitive = true
# }
