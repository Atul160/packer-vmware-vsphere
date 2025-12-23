# -------------------------------------------------------------------
# SYNOPSIS:
#   This Packer build automates creation of an Ubuntu Server
#   template on vSphere (ESXi 8.x).
#
# DESCRIPTION:
#   The flow performs these main steps:
#     1. Loads configuration variables (vSphere, OS, ISO, credentials)
#     2. Collects Git metadata for traceability
#     3. Generates a VM name and notes with build info
#     4. Boots a VM from Ubuntu ISO + cloud-init ISO (cidata)
#     5. Performs unattended installation via Subiquity + cloud-config
#     6. Connects over SSH and runs Ansible provisioning
#     7. Optionally converts the VM to a template or exports to Content Library
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# 🧱 GIT METADATA COLLECTION
# -------------------------------------------------------------------
# Used for traceability — embeds commit info, author, and build time
# into VM notes in vSphere for easy auditing.

data "git-repository" "cwd" {}
data "git-commit" "cwd" {}

# -------------------------------------------------------------------
# 🧮 LOCAL VARIABLES
# -------------------------------------------------------------------
# Define derived values such as timestamps, names, Git commit info,
# ISO paths, and user-data sources for cloud-init.

locals {
  # Build identification
  builder              = "Hashicorp Packer ${packer.version}"
  build_date           = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  git_branch_name      = data.git-repository.cwd.head
  git_commit_hash      = data.git-commit.cwd.hash
  git_commit_short_sha = substr(data.git-commit.cwd.hash, 0, 7)
  git_commit_message   = regex_replace(data.git-commit.cwd.message, "[^\\w\\s]", "$1W")
  git_commit_author    = data.git-commit.cwd.author
  git_commit_committer = data.git-commit.cwd.committer
  git_commit_timestamp = data.git-commit.cwd.timestamp

  # VM notes for traceability (visible in vCenter)
  vm_notes = join(
    "\n",
    compact(
      [
        "Builder: ${local.builder}",
        "Build Date: ${local.build_date}",
        "Branch: ${local.git_branch_name}",
        "Hash: ${local.git_commit_hash}",
        "Author: ${local.git_commit_author}",
        "Committer: ${local.git_commit_committer}",
        "Commit Message: ${local.git_commit_message}",
        "Commit Timestamp: ${local.git_commit_timestamp}",
        "Additional Notes:",
        var.vm_notes
      ]
    )
  )

  # ISO Source Paths (content library or datastore)
  iso_paths = {
    content_library = "${var.content_library_iso_source}/${var.iso_content_library_item}/${var.iso_file}",
    # datastore       = "[${var.iso_datastore}] ${var.iso_datastore_path}/${var.iso_file}"
  }

  # Cloud-init files (meta-data + user-data)
  data_source_content = {
    "/meta-data" = file("${abspath(path.root)}/install-types/${var.install_type}/data/meta-data")
    "/user-data" = templatefile("${abspath(path.root)}/install-types/${var.install_type}/data/user-data.pkrtpl.hcl", {
      build_username           = var.build_username
      build_password_encrypted = var.build_password_encrypted
      ssh_authorized_keys      = distinct(concat([var.build_key], var.additional_build_keys))
      ssh_allow_pw             = var.ssh_allow_pw
      vm_guest_os_cloudinit    = var.vm_guest_os_cloudinit
      additional_packages      = var.additional_packages
    })
  }

  # VM naming pattern (unique per build)
  vm_build_name = join(
    "-",
    compact(
      [
        "img",
        var.vm_guest_os_family,
        var.vm_guest_os_name,
        var.vm_guest_os_version,
        var.install_type,
        formatdate("YYYYMMDD-hhmm", timestamp()),
        local.git_commit_short_sha
      ]
    )
  )

  # VM base name (used in Content Library or template name)
  vm_name = join(
    "-",
    compact(
      [
        var.vm_guest_os_family,
        var.vm_guest_os_name,
        var.vm_guest_os_version,
        var.install_type
      ]
    )
  )
}

# local "build_password_plain" {
#     expression = vault("kv/data/github/take-two/abc-packer-vmware-vsphere", "build_password_plain")
#     sensitive  = true
# }

# -------------------------------------------------------------------
# 💿 VSPHERE ISO BUILDER DEFINITION
# -------------------------------------------------------------------
# Defines how to connect to vCenter, VM hardware configuration,
# boot commands, provisioning flow, and export options.

source "vsphere-iso" "ubt-server-ltsc" {

  # --- vCenter Connectivity ---
  username            = var.vSphere_username
  password            = var.vSphere_password
  vcenter_server      = var.vcenter_server
  insecure_connection = var.vsphere_insecure_connection

  # --- vSphere Target Settings ---
  create_snapshot = "false"
  datacenter      = var.datacenter
  datastore       = var.datastore
  folder          = var.folder
  cluster         = var.cluster

  # --- VM Hardware Settings ---
  vm_name              = local.vm_build_name
  guest_os_type        = var.vm_guest_os_type
  firmware             = var.vm_firmware
  CPUs                 = var.vm_cpu_count
  CPU_hot_plug         = var.vm_cpu_hot_add
  RAM                  = var.vm_mem_size
  RAM_hot_plug         = var.vm_mem_hot_add
  cdrom_type           = var.vm_cdrom_type
  disk_controller_type = var.vm_disk_controller_type

  # --- Disk Settings ---
  storage {
    disk_size             = var.vm_disk_size
    disk_thin_provisioned = var.vm_disk_thin_provisioned
  }

  # --- Network Configuration ---
  network_adapters {
    network      = var.network
    network_card = var.vm_network_card
  }

  # Optional: vm_version, reattach_cdroms, etc.
  remove_cdrom         = var.remove_cdrom
  reattach_cdroms      = var.vm_cdrom_count
  tools_upgrade_policy = var.tools_upgrade_policy
  notes                = local.vm_notes

  # --- Installation Media (ISO + Cloud-Init) ---
  iso_paths  = [local.iso_paths.content_library]
  cd_content = local.data_source_content
  cd_label   = "cidata"

  # --- Boot Settings ---
  boot_order        = var.vm_boot_order
  boot_wait         = var.vm_boot_wait
  boot_command      = var.vm_boot_command
  ip_wait_timeout   = var.ip_wait_timeout
  ip_settle_timeout = var.ip_settle_timeout

  # --- Shutdown Command ---
  shutdown_command = "sleep 5 && sudo -S -E shutdown -P now"
  shutdown_timeout = var.shutdown_timeout

  # --- SSH Communicator Configuration ---
  communicator = "ssh"
  ssh_username = var.build_username
  ssh_password = var.build_password_plain
  # ssh_private_key_file = var.build_private_key_path
  ssh_port    = var.communicator_port
  ssh_timeout = var.communicator_timeout
  # optionally disable agent forwarding/agent auth to force password usage
  ssh_agent_auth = false

  # --- Template / Content Library Export ---
  convert_to_template = var.template_conversion

  # Dynamically export to content library if enabled
  dynamic "content_library_destination" {
    for_each = var.content_library_enabled ? [1] : []
    content {
      library     = var.content_library_destination
      name        = local.vm_name
      description = local.vm_notes
      ovf         = var.content_library_ovf
      destroy     = var.content_library_destroy
      skip_import = var.content_library_skip_export
    }
  }
}

# -------------------------------------------------------------------
# ⚙️ BUILD EXECUTION BLOCK
# -------------------------------------------------------------------
# Defines what happens *after* the OS is installed and SSH is ready.
# Here, Ansible is used as a post-provisioner for software installation,
# system hardening, and configuration.

build {
  name    = "ubt-server-ltsc"
  sources = ["source.vsphere-iso.ubt-server-ltsc"]

  # Upload ansible folder into VM
  # provisioner "file" {
  #   source      = "${path.cwd}/ansible"
  #   destination = "/tmp/ansible"
  # }
  # provisioner "file" {
  #   source      = "${path.cwd}/infra/scripts/ubuntu/puppet-csr.sh"
  #   destination = "/tmp/puppet-csr.sh"
  # }

  # shell provisioner runs shell scripts on the machine Packer builds
  # shell-local provisioner runs shell scripts on the machine running Packer
  #   provisioner "shell" {
  #     pause_before = "30s"
  #     max_retries  = 3

  #     # All Packer vars must be passed as environment variables
  #     env = {
  #       DEBIAN_FRONTEND = "noninteractive"
  #       build_key        = var.build_key
  #       ansible_key      = var.ansible_key
  #     }

  #     inline = [
  #       "set -e",

  #       "echo '=== Setting non-interactive frontend for apt/dpkg ==='",
  #       "export DEBIAN_FRONTEND=noninteractive",
  #       "export DEBCONF_NONINTERACTIVE_SEEN=true",
  #       "export APT_LISTCHANGES_FRONTEND=none",
  #       "export NEEDRESTART_MODE=a",

  #       "echo '=== Waiting for any existing apt/dpkg locks to be released ==='",
  #       "while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do",
  #       "echo 'Waiting for apt/dpkg lock...'",
  #       "sleep 5",
  #       "done",

  #       "echo '=== Fix any broken dpkg configuration ==='",
  #       "sudo dpkg --configure -a || true",

  #       "echo '=== Cleaning apt cache ==='",
  #       "sudo apt-get clean",

  #       "echo 'NEEDRESTART_MODE=a' | sudo tee /etc/needrestart/needrestart.conf",

  #       "echo '=== Updating apt repositories ==='",
  #       "sudo apt-get -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' -qq -y update ",

  #       "echo '=== Upgrading installed packages ==='",
  #       "sudo apt-get -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' -qq -y upgrade >/dev/null 2>&1",

  #       "echo '=== Installing Ansible inside the VM ==='",
  #       "sudo apt-get install -y -qq software-properties-common",
  #       "sudo add-apt-repository --yes --update ppa:ansible/ansible >/dev/null 2>&1",
  #       "sudo apt-get install -y -qq ansible python3 python3-pip",

  #       "echo '=== Setting Ansible environment variables ==='",
  #       "export ANSIBLE_CONFIG='/tmp/ansible/ansible.cfg'",

  #       "echo '=== Installing Ansible Galaxy roles and collections ==='",
  #       "ansible-galaxy install -r '/tmp/ansible/linux-requirements.yml' --force-with-deps --roles-path '/tmp/ansible/roles'",
  #       "ansible-galaxy collection install --force-with-deps community.general ansible.posix",

  #       "echo '=== Running Ansible playbook ==='",
  #       <<EOF
  # ansible-playbook '/tmp/ansible/linux-playbook.yml' \
  #   -i "localhost," \
  #   --connection=local \
  #   --extra-vars "display_skipped_hosts=false" \
  #   --extra-vars "build_username=${var.build_username}" \
  #   --extra-vars "ansible_username=${var.ansible_username}" \
  #   --extra-vars "enable_cloudinit=${var.vm_guest_os_cloudinit}" \
  #   --extra-vars "{\"build_key\": \"$build_key\", \"ansible_key\": \"$ansible_key\"}"
  # EOF
  #       ,
  #     "echo '=== Cleaning up temporary Ansible files ==='",
  #     "sudo rm -rf /tmp/ansible",
  #     ]
  #   }

  provisioner "ansible" {
    # Execution context
    user = var.build_username

    # Playbook & Galaxy
    playbook_file          = "${path.cwd}/ansible/linux-playbook.yml"
    galaxy_file            = "${path.cwd}/ansible/linux-requirements.yml"
    galaxy_force_with_deps = true

    # Let Packer manage role & collection paths
    galaxy_force_install = true

    # Environment variables
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.cwd}/ansible/ansible.cfg",
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3",
    ]

    # Extra vars (NO QUOTING)
    extra_arguments = [
      "--extra-vars", "display_skipped_hosts=false",
      "--extra-vars", "build_username=${var.build_username}",
      "--extra-vars", "build_key='${var.build_key}'",
      "--extra-vars", "ansible_username=${var.ansible_username}",
      "--extra-vars", "ansible_key='${var.ansible_key}'",
      "--extra-vars", "enable_cloudinit=${var.vm_guest_os_cloudinit}",
    ]

    # SSH stability
    ansible_ssh_extra_args = [
      "-o StrictHostKeyChecking=no",
      "-o UserKnownHostsFile=/dev/null",
      "-o ControlMaster=auto",
      "-o ControlPersist=60s"
    ]

    # Timing / retries
    pause_before = "60s"
    max_retries  = 3
  }

}
