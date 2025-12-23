packer {
  required_plugins {
    vsphere = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/vsphere"
    }

    windows-update = {
      version = ">= 0.14.3"
      source  = "github.com/rgl/windows-update"
    }
  }
}
