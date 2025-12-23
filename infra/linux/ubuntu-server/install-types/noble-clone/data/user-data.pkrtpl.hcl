#cloud-config
# Ubuntu Server 24.04 LTS

autoinstall:
  version: 1
  apt:
    geoip: true
    preserve_sources_list: false
    primary:
      - arches: [amd64, i386]
        uri: http://archive.ubuntu.com/ubuntu
      - arches: [default]
        uri: http://ports.ubuntu.com/ubuntu-ports
  early-commands:
    - sudo systemctl start ssh
  locale: en_US
  keyboard:
      layout: us
  network:
    network:
      version: 2
      ethernets:
        ens:
          match:
            name: ens*
          dhcp4: true
          dhcp-identifier: mac
          critical: yes
  storage:
    layout:
      name: direct

  identity:
    hostname: ubuntu-server
    username: ${build_username}
    password: ${build_password_encrypted}

  ssh:
    install-server: true
    allow-pw: true
    authorized-keys:
%{ for key in ssh_authorized_keys ~}
      - ${key}
%{ endfor ~}

  packages:
    - openssh-server
    - open-vm-tools
    - cloud-init
%{ for package in additional_packages ~}
    - ${package}
%{ endfor ~}

  user-data:
    disable_root: false

  late-commands:
    - echo '${build_username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${build_username}
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${build_username}

    # ✅ enable password authentication in SSH config
    - curtin in-target --target=/target -- sed -i 's/^#PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config || true
    - curtin in-target --target=/target -- sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config || true

    # ✅ restart sshd for good measure
    - curtin in-target --target=/target -- systemctl restart ssh || true
