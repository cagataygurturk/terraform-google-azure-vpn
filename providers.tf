terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2"
    }

    google = {
      source  = "hashicorp/google"
      version = ">= 5.7, < 6"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.7, < 6"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}