packer {
  required_version = ">= 1.10.0"
  required_plugins {
    vsphere = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/vsphere"
    }
    ansible = {
      version = ">= 1.1.4"
      source  = "github.com/hashicorp/ansible"
    }
    git = {
      version = ">= 0.6.5"
      source  = "github.com/ethanmdavidson/git"
    }
  }
}
