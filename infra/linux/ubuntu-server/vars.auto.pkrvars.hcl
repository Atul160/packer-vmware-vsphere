// BASE SET OF VARIABLE ASSIGNMENTS
// These can be overridden for each install-type in the respective `vars.pkrvars.hcl`
// Image Type must be configured within the above Packer variables file

// Guest OS Settings
vm_guest_os_language = "en_US"
vm_guest_os_keyboard = "us"
vm_guest_os_timezone = "UTC"
vm_guest_os_family   = "linux"
vm_guest_os_name     = "ubuntu"
vm_guest_os_type      = "ubuntu64Guest"
vm_guest_os_cloudinit = false

// Virtual Machine Hardware Settings
vm_firmware              = "efi-secure"
vm_cdrom_type            = "sata"
vm_cdrom_count           = 1
vm_cpu_count             = 4
vm_cpu_hot_add           = false
vm_mem_size              = 8192
vm_mem_hot_add           = false
vm_disk_size             = 40960
vm_disk_controller_type  = ["pvscsi"]
vm_disk_thin_provisioned = true
vm_network_card          = "vmxnet3"
vm_version               = 19
tools_upgrade_policy     = true
remove_cdrom             = true

// Boot Settings
vm_boot_order = "disk,cdrom"
vm_boot_wait  = "5s"

// Communicator Settings
ip_wait_timeout      = "20m"
ip_settle_timeout    = "2m"
communicator_port    = 22
communicator_timeout = "30m"
shutdown_timeout     = "15m"
ssh_allow_pw          = true

// Default Account Credentials
build_username           = "ubuntu"
build_password_plain     = "format4DUCK-jenkins@ramen"
build_password_encrypted = "$6$xjc1t39/HJcB5u$Q0jGp4o4JzWlzP60SR2ZpbIHXeGYvf2wsMpq0pQQbkA2vraYu05/eQoZ82wkAabcD/uQizE7LidjguHhhR2mPy0"
build_key                = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbE65UmbYYDQOjMqL34y3zfkJRXp/WAOTGntY4xW2Rm packer@abcgames.com" # Prod Packer Provisioning Key
build_private_key_path   = "~/.ssh/id_ed25519_packer"

// Ansible Account Credentials
ansible_username = "svcabcansible"
ansible_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOG9cxp+EcdY+jz3qcbsb4WDB89jJvrMc0SsMFpjMgzI ansible@abcgames.com" # Ubuntu 22.04 Infrabase Template for the moment

# Additional Configuration
# Base packages are installed during build via user-data templates
# Common packages are handled via Ansible in ${repopath}/ansible/roles/base/vars/main.yml
additional_packages   = []
additional_build_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvqpG9V4IAj2otCRIAPYew7ahYc8oB8+nTusTTEU4lO abcadmin" #1password Linux abcadmin so we can actually SSH into this node later
]
