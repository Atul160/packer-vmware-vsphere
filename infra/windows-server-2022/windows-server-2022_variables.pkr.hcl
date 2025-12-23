variable "vcenter_server" {
  type        = string
  description = "vCenter Server used for deploying the template"
}

variable "vSphere_username" {
  type        = string
  default     = "svcabcpacker@abc.corp"
  description = "User account with permissions to modify content libraries"
}

variable "vSphere_password" {
  type        = string
  sensitive   = true
  description = "Credentials which will be used for vSphere_username"
}

variable "passwdstateapikey" {
  type        = string
  sensitive   = true
  default     = "nothingtoseehere"
  description = "API Key Used to pull creds for build related items - mapping drives etc"
}

variable "datacenter" {
  type        = string
  description = "The default datacenter will be used for templates"
}

variable "cluster" {
  type        = string
  description = "The default cluster which will be used for templates"
}

variable "network" {
  type        = string
  description = "This is the default network which will be attached to the vm"
}

variable "datastore" {
  type        = string
  description = "The target storage destination which will be saved to the template"
}

variable "primary_disk_size" {
  type        = number
  default     = 81920
  description = "The size of the primary OS disk"
}

variable "folder" {
  type        = string
  description = "Default location where the template will be built before being migrated to Content Library"
}

variable "winrm_username" {
  type        = string
  default     = "Administrator"
  description = "The account which will be used to connect directly to the vm after setup"
}

variable "winrm_password" {
  type        = string
  sensitive   = true
  description = "This account will be used to connect directly to the server via winrm"
  default     = "Temppassword!Password"
}

variable "build_password_plain" {
  type        = string
  sensitive   = true
  description = "The password used for the local build account in Linux builds"
}

variable "content_library_iso_source" {
  type        = string
  description = "The default location used for operating system ISOs and VMware Tools"
}

variable "content_library_destination" {
  type        = string
  description = "The default location used for vm storage once completed"
}

variable "iso_path" {
  type        = string
  default     = "[]"
  description = "This is the location for the iso file stored on vSphere"
}

variable "vmware_tools_version" {
  type        = string
  default     = "[]"
  description = "This version of VMware tools to install.  Tools ISOs are stored in the content library"
}

variable "install_type" {
  type        = string
  description = "The OS format which will be used. This can be either gui or core"
}

variable "vm_notes" {
  type        = string
  description = "Any notes which will be added to the VM template name"
}

variable "vm_name" {
  type        = string
  description = "The name which will be used for the VM build - the resulting packer artefact that's published to the content library"
}

variable "vm_build_name" {
  type        = string
  description = "The name which will be used for runtime build image"
}

variable "ovf_template" {
  type        = bool
  default     = true
  description = "Configures the template either as a VM template or an ovf template"
}

variable "update_count" {
  type        = number
  default     = 1000
  description = "The number of updates to pull down from windows update"
}
