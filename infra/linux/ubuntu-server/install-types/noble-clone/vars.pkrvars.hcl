// Image Type
install_type = "noble-clone"

// Guest OS Settings
vm_guest_os_version   = "24.04-lts"
vm_guest_os_cloudinit = false

// VM Boot Settings
vm_boot_command = [
  "<wait3s>c<wait3s>",
  "linux /casper/vmlinuz --- autoinstall ds=\"nocloud\"",
  "<enter><wait>",
  "initrd /casper/initrd",
  "<enter><wait>",
  "boot",
  "<enter>"
]

// Source Build ISO
iso_content_library_item = "ubuntu-24.04-live-server-amd64"
iso_file                 = "ubuntu-24.04.1-live-server-amd64.iso"

// Default User Configuration
build_username           = "abcadmin"
build_password_encrypted = "$6$T16kAQAm3WxL.L7R$KQ5mfYk7XDZ4Pw41ZnFlPDruFpbUKyrXDOwa9RNHF5/5NpBsoSCpgpdHdwqeZU61WdaP1hrlAinFiznvzg84y/"

// Additional Configuration
vm_notes = "Image can be cloned from template / content library with the usual abcadmin password"
