#!/bin/bash
# Define the target directory for packages and APT sources
packages_dir="/proxmox/apt/packages"
apt_dir="/proxmox/apt"

# Create the directories
mkdir -p "$packages_dir"
mkdir -p "$apt_dir"

# Function to update sources and keys
update_sources_and_keys() {
    echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 
    apt-get update
}

# Function to download packages
download_packages() {
    package_name=$1

    echo "Downloading packages for $package_name..."
    dependencies=$(apt-rdepends $package_name | grep -v "^ " | grep -v "Depends")

    for dep in $dependencies; do
        echo "Downloading $dep..."
        apt-get install --download-only -y $dep
    done

    echo "Moving downloaded packages for $package_name to $packages_dir..."
    find /var/cache/apt/archives -name "*.deb" -exec mv {} "$packages_dir/" \;
}

# Update sources and keys
update_sources_and_keys

# Install and configure apt-rdepends
apt-get install apt-rdepends -y

# Update and upgrade system to download any additional packages
apt-get update
apt-get full-upgrade --download-only -y

# Move all downloaded packages to the target directory
find /var/cache/apt/archives -name "*.deb" -exec mv {} "$packages_dir/" \;

# Download packages for Proxmox VE, Ansible, and their dependencies
download_packages "proxmox-default-kernel"
download_packages "proxmox-ve postfix open-iscsi openssh-client openssh-sftp-server openssh-server htop"
download_packages "ansible"

# Copy the sources.list, sources.list.d, and lists to the target APT directory
cp /etc/apt/sources.list "$apt_dir/"
cp -r /etc/apt/sources.list.d "$apt_dir/"
cp -r /var/lib/apt/lists "$apt_dir/"

echo "Download and copy completed. Packages and APT sources are in '$packages_dir' and '$apt_dir'."
