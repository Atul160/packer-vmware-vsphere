# abc-Packer-VMware-vSphere

## 🧭 Overview

The **abc-Packer-VMware-vSphere** project automates the creation of pre-configured virtual machine templates for both **Ubuntu Linux** and **Windows** operating systems.

These templates are built using **HashiCorp Packer** and are designed to be deployed on **VMware vSphere** environments.
The project supports multiple OS versions and configurations, making it highly customizable for various enterprise use cases.

This repository provides a fully automated workflow for building, configuring, and exporting VM templates — ensuring **consistency, security, and scalability** across your virtualized infrastructure.

---

## ✨ Features

### 🖥️ Multi-OS Support

- Ubuntu Server (22.04, 24.04, and other versions)
- Windows Desktop and Server (Windows 11, Windows Server 2022, 2025)

### ⚙️ Cloud-Init and Sysprep Integration

- Automates OS configuration during the build process
- Supports both Linux (`cloud-init`) and Windows (`unattend.xml`) workflows

### 🔒 Enterprise-Grade Security

- SSH key-based authentication for Linux VMs
- Encrypted passwords for Windows and Linux users
- Configurable firewall and network settings

### 🧩 Customizable Configurations

- Modular design with environment-specific variables
- Support for additional packages, tools, and configurations

### 🤖 Ansible Integration

- Post-build provisioning using **Ansible** for advanced configuration
- Role-based deployment of tools like **Puppet**, monitoring agents, and more

### ☁️ VMware-Specific Features

- VMware Tools upgrade policy configuration
- Support for **VMware Content Libraries**
- Network adapter and disk layout customization

### 📈 Scalable and Reproducible

- Fully automated builds ensure consistency across environments
- Easily extendable for new OS versions or configurations

---

## 🗂️ Repository Structure

The repository is organized as follows:

```
abc-Packer-VMware-vSphere/
├── ansible/                     # Ansible playbooks and configuration
│   ├── ansible.cfg              # Ansible configuration file
│   └── roles/                   # Ansible roles for post-build provisioning
├── infra/                       # Packer configurations for VM builds
│   ├── linux/                   # Linux-specific configurations
│   │   ├── ubuntu-server/       # Ubuntu Server builds
│   │   │   ├── install-types/   # Different Ubuntu install types (e.g., noble-clone, jammy-clone)
│   │   │   ├── vars.auto.pkrvars.hcl  # Base variables for Ubuntu builds
│   │   │   └── ubuntu-server.pkr.hcl # Packer HCL for Ubuntu
│   ├── windows/                 # Windows-specific configurations
│   │   ├── install-types/       # Different Windows install types
│   │   ├── vars.auto.pkrvars.hcl  # Base variables for Windows builds
│   │   └── windows-server.pkr.hcl # Packer HCL for Windows
│   └── scripts/                 # Helper scripts for provisioning and configuration
├── secrets/                     # Encrypted secrets (e.g., SSH keys, passwords)
├── build-environments/          # Environment-specific variable files
├── .gitignore                   # Git ignore file
└── README.md                    # Project documentation
```

---

## 🚀 Getting Started

### 🧩 Prerequisites

#### VMware vSphere Environment

- Access to a **vSphere** environment with appropriate permissions
- Optional: **Content Library** for storing VM templates

#### Tools

- [HashiCorp Packer](https://www.packer.io/) (v1.7+)
- [Ansible](https://www.ansible.com/) (optional for post-build provisioning)
- VMware CLI tools (e.g., `govc` for vSphere interaction)

#### Credentials

- vSphere credentials with permissions to create VMs and upload templates
- SSH keys for Linux builds
- Encrypted passwords for Windows builds

---

### ⚙️ Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/your-org/abc-Packer-VMware-vSphere.git
cd abc-Packer-VMware-vSphere
```

#### 2. Install Dependencies

- Install Packer → Follow Packer Installation Guide
- Install Ansible (optional) → sudo apt install ansible -y

#### 3. Configure Variables

Update the vars.auto.pkrvars.hcl files for both Linux and Windows builds with your environment-specific settings.

#### 4. Set Secrets

Add your vSphere credentials and SSH keys to the secrets/ directory.

## 🧱 Building VM Templates

### 🐧 Linux (Ubuntu) Build

```bash
cd ./infra/linux/ubuntu-server/
packer init .         # Install packer requirements
packer build  -var-file=./secrets/prod_infra.secrets.pkrvars.hcl  -var-file=./infra/linux/ubuntu-server/install-types/jammy-clone/vars.pkrvars.hcl -var-file=./build-environments/prod_infra.pkrvars.hcl ./infra/linux/ubuntu-server
```

### Windows Build

```bash
cd ./infra/windows-server-2022/
packer init .         # Install packer requirements
packer build -var-file="./build-environments/prod_infra.pkrvars.hcl" -var-file="./secrets/prod_infra.secrets.pkrvars.hcl" -var-file="./infra/windows-server-2022/install-types/default_gui/vars.pkrvars.hcl" ./infra/windows-server-2022/
```

## 🧰 Customization

### 🐧 Linux Builds

- Modify user-data.pkrtpl.hcl for cloud-init configurations
- Add additional packages in vars.auto.pkrvars.hcl

### 🪟 Windows Builds

- Modify autounattend.xml for Sysprep configurations
- Add post-build scripts under the scripts/ directory

## 🤝 Contributing

We welcome contributions to improve this project!

- Fork the repository
- Create a feature branch

  ```bash
    git checkout -b feature/my-new-feature
  ```

- Commit your changes and submit a Pull Request

## 📬 Contact

For questions or support, please contact the abc Infrastructure Engineering Team at:
<systems@abcgames.com>

## Build Statuses

![Ubuntu 22.04 Jammy - Infrastructure - Production](https://github.com/take-two/abc-packer-vmware-vsphere/actions/workflows/infra-ubuntu-server-2204-infra-prod.yml/badge.svg)

![Ubuntu 24.04 Noble - Infrastructure - Production](https://github.com/take-two/abc-packer-vmware-vsphere/actions/workflows/infra-ubuntu-server-2404-infra-prod.yml/badge.svg)

![Windows Server 2022 - Infrastructure - Production](https://github.com/take-two/abc-packer-vmware-vsphere/actions/workflows/infra-windows-server-2022-infra-prod.yml/badge.svg)

![Windows Server 2022 - Infrastructure - Production - LA1](https://github.com/take-two/abc-packer-vmware-vsphere/actions/workflows/infra-windows-server-2022-infra-prod-la1.yml/badge.svg)

![Windows Server 2025 - Infrastructure - Production](https://github.com/take-two/abc-packer-vmware-vsphere/actions/workflows/infra-windows-server-2025-infra-prod.yml/badge.svg)

![Windows Server 2025 - Infrastructure - Production - LA1](https://github.com/take-two/abc-packer-vmware-vsphere/actions/workflows/infra-windows-server-2025-infra-prod-la1.yml/badge.svg)

![Windows Desktop 11 - Infrastructure - Production](https://github.com/take-two/abc-packer-vmware-vsphere/actions/workflows/infra-windows-desktop-11-infra-prod-la1.yml/badge.svg)
