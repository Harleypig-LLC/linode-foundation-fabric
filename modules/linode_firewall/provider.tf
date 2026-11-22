terraform {
  required_version = ">= 1.11"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 4.10"
    }
  }
}
