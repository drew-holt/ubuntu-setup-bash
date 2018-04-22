#!/bin/bash
# Drew Holt <drew@invadelabs.com>
# script to setup newly installed local environment in ubuntu 17.10 for packages without a repo
#
# shellcheck disable=SC2164

# install already gathered packages that arent in ubuntu repos
# XXX find a better way to dl these
local_installers () {
  if ! dmesg | grep -i hypervisor; then
    if [ ! -d /mnt/hdd ]; then
      sudo mkdir /mnt/hdd
      sudo mount /dev/vg_hdd/lv_hdd /mnt/hdd
      cd /mnt/hdd/iso_installers/ubuntu-installers
      wait_apt; sudo apt-get install -qy \
        ./vagrant_2.0.3_x86_64.deb \
        ./virtualbox-5.2_5.2.8-121009_Ubuntu_zesty_amd64.deb \
        ./chefdk_2.4.17-1_amd64.deb
    fi
  fi
}

# virtualbox extras pack XXX write better check for version of vbox and if it is already downloaded
install_vb_extras () {
  if [ -f /usr/bin/VBoxManage ]; then
    if ! vboxmanage list extpacks | grep 1; then
      location="/mnt/hdd/iso_installers/ubuntu-installers/"
      echo y | sudo VBoxManage extpack install "$location"/Oracle_VM_VirtualBox_Extension_Pack-5.2.8.vbox-extpack
    fi
  fi
}

# vagrant plugins XXX would be better to compare array of whats installed and what needs to be installed
install_vagrant_plugins () {
  if [ -f /usr/bin/vagrant ]; then
    vg_plugins=("berkshelf" "vagrant-berkshelf")

    for i in "${vg_plugins[@]}"; do
      if ! vagrant plugin list | cut -f 1 -d" " | grep -E ^"$i" >/dev/null; then
        vagrant plugin install "$i"
      fi
    done
  fi
}

local_installers
install_vb_extras
install_vagrant_plugins
