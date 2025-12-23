# SYNOPSIS:
# 	This build file will generate a new packer build on windows 11

# DESCRIPTION:

# NOTES:

# RELEASE_NOTES:

# REQUIRED_VARS
# 	vSphere_password: This is the password which is used to connect to vSphere and should not be included in a file

// SOURCE BLOCK: Defines the source image and VM settings
source "vsphere-iso" "win-desktop11" {

  // vCenter Connection - values provided by CI/CD
  vcenter_server        = var.vcenter_server
  username              = var.vSphere_username
  password              = var.vSphere_password
  insecure_connection   = true

  // vSphere Target Environment
  datacenter           = var.datacenter
  cluster              = var.cluster
  datastore            = var.datastore
  folder               = var.folder

  // VM Configuration
  vm_name              = "img-${var.vm_build_name}"
  guest_os_type        = "windows9_64Guest"
  vm_version           = 19
  firmware              = "efi"
  # vTPM                 = true
  CPUs                 = 4
  RAM                  = 8192
  disk_controller_type = ["pvscsi"]
  notes                = "${var.vm_notes} BuildDate: ${timestamp()}"
  create_snapshot      = false
  shutdown_timeout     = "1h"
  storage {
    disk_size             = var.primary_disk_size
    disk_thin_provisioned = true
  }
  network_adapters {
    network      = var.network
    network_card = "vmxnet3"
  }

  # TPM + Secure Boot workaround
  # These are passed as VMX configuration_parameters
  # (same as setting in vSphere UI → VM Options → Advanced → Edit Configuration)
  configuration_parameters = {
    "efi.secureBoot.enabled" = "TRUE"
    "security.tpm.version"   = "v2.0"
    "security.tpm.enabled"   = "TRUE"
  }

  // OS Installation from ISO
  iso_paths    = [
    "${var.content_library_iso_source}/${var.iso_path}",
    "${var.content_library_iso_source}/vmware-tools-windows-${var.vmware_tools_version}/windows.iso"
    ]
  remove_cdrom = true

  // Unattended Installation
  boot_command         = ["<enter>", "<spacebar>"]
  boot_order           = "disk,cdrom,floppy"
  boot_wait            = "1s"
  floppy_files = [
    "${path.root}/install-types/${var.install_type}/autounattend.xml",
    "${path.root}/../scripts/windows/*"
    ]

  // Communicator Settings
  communicator   = "winrm"
  winrm_insecure = true
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password

  // Destination of OVF Template
  content_library_destination {
    library     = var.content_library_destination
    name        = "${var.vm_name}"
    description = "${var.vm_notes} BuildDate: ${timestamp()}"
    ovf         = var.ovf_template
    destroy     = "true"
  }

}

// BUILD BLOCK: Defines the provisioning steps
build {
  name    = "win-desktop11"
  sources = ["source.vsphere-iso.win-desktop11"]

  // Run windows updates 1
  provisioner "powershell" {
    elevated_password = var.winrm_password
    elevated_user     = var.winrm_username
    script            = "./infra/scripts/windows/api-force-windowsupdates-noreboot.ps1"
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
    pause_before    = "180s"
  }

  // Run windows updates 2
  provisioner "powershell" {
    elevated_password = var.winrm_password
    elevated_user     = var.winrm_username
    script            = "./infra/scripts/windows/api-force-windowsupdates-noreboot.ps1"
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
    pause_before    = "180s"
  }

  # Applying Post-Build Configurations (Placeholder)
  # provisioner "powershell" {
  #   elevated_password = var.winrm_password
  #   elevated_user     = "Administrator"
  #   script            = "./infra/scripts/windows/Prepare-Windows.ps1"
  # }

  # Running Sysprep to clean and generalize the image
  provisioner "powershell" {
    elevated_password = var.winrm_password
    elevated_user     = "Administrator"
    inline = [
      "Write-Output 'Performing sysprep configuration...'",
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit",
      "while($true) { try { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -eq 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; break }else{ Write-Output $imageState.ImageState } } Catch {}; Start-Sleep -s 10 }"
    ]
  }

}
