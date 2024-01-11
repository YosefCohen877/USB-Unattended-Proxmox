#!/bin/bash
# Define directories
kernel_dir="./kernel"
pve_dir="./pve"
system_dir="./system"
ansible_dir="./ansible"

# Create directories
mkdir -p "$kernel_dir"
mkdir -p "$pve_dir"
mkdir -p "$system_dir"
mkdir -p "$ansible_dir"

# Function to update sources and keys
update_sources_and_keys() {
    echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 
    apt-get update
}

# Function to download and move packages
download_packages() {
    package_name=$1
    target_dir=$2

    echo "Downloading packages for $package_name..."
    dependencies=$(apt-rdepends $package_name | grep -v "^ " | grep -v "Depends")

    for dep in $dependencies; do
        echo "Downloading $dep..."
        apt-get install --download-only -y $dep
    done

    echo "Moving downloaded packages for $package_name to $target_dir..."
    find /var/cache/apt/archives -name "*.deb" -exec mv {} "$target_dir/" \;
}

# Update sources and keys
update_sources_and_keys

# Install and configure apt-rdepends
apt-get install apt-rdepends -y

# Update and upgrade system to download any additional packages
apt-get update
apt-get full-upgrade --download-only -y

# Move system update packages to the system directory
find /var/cache/apt/archives -name "*.deb" -exec mv {} "$system_dir/" \;

# Download Proxmox VE kernel packages
download_packages "proxmox-default-kernel" "$kernel_dir"

# Download Proxmox VE related packages and their dependencies
download_packages "proxmox-ve postfix open-iscsi openssh-client openssh-sftp-server openssh-server" "$pve_dir"

# Download Ansible and its dependencies
download_packages "ansible" "$ansible_dir"

echo "Download completed. Packages are in 'kernel', 'pve', 'system', and 'ansible' directories."
