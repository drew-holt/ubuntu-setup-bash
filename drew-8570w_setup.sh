#!/bin/bash
# Drew Holt <drew@invadelabs.com>
# script to setup newly installed local environment in ubuntu 17.10
#
# shellcheck disable=SC1001,SC2086,SC2119,SC2120
# SC1001: This \c will be a regular 'c' in this context.
# SC2086: Double quote to prevent globbing and word splitting.
# SC2119: Use set_shell_stuff "$@" if function's $1 should mean script's $1.
# SC2120: set_aliases references arguments, but none are ever passed.

set -x
set -e

# passwordless sudo for local box
check_sudo () {
  if ! sudo grep drew /etc/sudoers; then
    sudo sh -c 'echo "drew ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
  fi
}

# gnome3 peronalizations and prefrences
gsettings_personalizations () {
  if [[ ! $(gsettings get org.gnome.desktop.interface clock-format) == "'12h'" ]]; then
    # set 12 hour time
    gsettings set org.gnome.desktop.interface clock-format 12h

    # set natural scrolling on mouse not touchpad, GUI under 'Settings > Mouse'
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

    # switch alt+tab to windows, not applications. GUI under 'Settings > Keyboard'
    gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward  "['<Alt><Shift>Tab']"

    # set gnome-terminal colors
    # e.x.: gsettings list-recursively "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
    # e.x.: gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/" login-shell true
    settings=("use-theme-colors false" "login-shell true" "default-show-menubar false" "foreground-color \
    'rgb(255,255,255)'" "background-transparency-percent 6" "background-color 'rgb(0,0,0)'" \
    "use-theme-transparency false" "scrollback-unlimited true" "use-transparent-background true")
    profile=$(gsettings get org.gnome.Terminal.ProfilesList default)
    profile=${profile:1:-1} # remove leading and trailing single quotes
    for i in "${settings[@]}"; do
      gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/" $i
    done

    # remove clutter
    if [ -d Documents/ ]; then
      rmdir Documents/ Music/ Public/ Templates/ Videos/
      rm examples.desktop
    fi
  fi
}

# set env and aliases
set_shell_stuff () {
  if ! grep rdesktop "$HOME"/.bashrc; then
    cat <<EOF >> $HOME/.bashrc
export PATH="$HOME/.local/bin:$PATH"
alias xclip='xclip -selection clipboard'
alias rdesktop='rdesktop -g 1280x720 -r clipboard:CLIPBOARD -r disk:share=/home/drew'
alias get_ip='_get_ip() { VBoxManage guestproperty get "$1" "/VirtualBox/GuestInfo/Net/1/V4/IP";}; _get_ip'
EOF
  fi
}

## disable popularity-contest XXX how dpkg-reconifgure with debconf selection non-interactively
# echo debconf popularity-contest/participate select false | sudo debconf-set-selections
# sudo dpkg-reconfigure popularity-contest

# oracle 8 add java repo
oracle_repo () {
  if [ ! -f /etc/apt/sources.list.d/webupd8team-ubuntu-java-artful.list ]; then
    sudo add-apt-repository -y ppa:webupd8team/java
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
  fi
}

# wait for apt lock release
wait_apt () {
while true;
  sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
  echo "waiting for apt lock"
  sleep 1
done
}

# install etckeeper first and initialize it
init_etckeeper () {
  if [ ! -d /etc/.git ]; then
    wait_apt; sudo apt-get install -qy etckeeper

    # set github here
    git config --global user.name "Drew Holt"
    git config --global user.email "drewderivative@gmail.com"

    sudo etckeeper init
    sudo find /etc/.git -type d -exec chmod 750 {} \;
  fi
}

# update repo cache if it's been longer than 2 hours
apt_update () {
  if [ -f /var/log/first.boot ]; then
    if [ "$(find /var/cache/apt/pkgcache.bin -mtime 2)" ]; then
      wait_apt; sudo apt-get -qy update
    fi
  else
    wait_apt; sudo apt-get -qy update
    sudo touch /var/log/first.boot
  fi
}

# dist-upgrade if upgrades are available
apt_upgrade () {
  if [ ! "$(/usr/lib/update-notifier/apt-check 2>&1 | cut -d ';' -f 1)" == "0" ]; then
    wait_apt; sudo apt-get -qy dist-upgrade
  fi
}


# install already gathered packages that arent in ubuntu repos
# XXX find a better way to dl the latest installers for these if they are not already on the network
# and try to create as many /etc/apt/sources.lists.d for these to add to main install_apt()
local_installers () {
  if ! dmesg | grep -i hypervisor; then
    if [ ! -d /mnt/hdd ]; then
      sudo mkdir /mnt/hdd
      sudo mount /dev/vg_hdd/lv_hdd /mnt/hdd
      cd /mnt/hdd/iso_installers/ubuntu-installers
      wait_apt; sudo apt-get install -qy ./atom-amd64.deb ./google-chrome-stable_current_amd64.deb \
        ./insync_1.4.4.37065-artful_amd64.deb ./slack-desktop-3.1.0-amd64.deb \
        ./vagrant_2.0.3_x86_64.deb ./virtualbox-5.2_5.2.8-121009_Ubuntu_zesty_amd64.deb \
        ./skypeforlinux-64.deb ./keybase_amd64.deb ./chefdk_2.4.17-1_amd64.deb
    fi
  fi
}

# add debconf for promptless install and apt-get install software
install_apt () {
  # for wireshark mscorefonts postfix prompts
  echo wireshark-common wireshark-common/install-setuid boolean true | sudo debconf-set-selections
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
  echo postfix postfix/mailname string drew-8570w.local | sudo debconf-set-selections
  echo postfix postfix/main_mailer_type string 'Local only' | sudo debconf-set-selections

  # install all the things
  wait_apt;
  DEBIAN_FRONTEND=noninteractive `#no prompting` sudo apt-get install -qy \
  keepass2 synergy gnome-tweak-tool chrome-gnome-shell `#tools` \
  vim vim-scripts vim-runtime vim-doc curl xd `#systools` \
  lm-sensors p7zip-full exfat-utils exfat-fuse libimage-exiftool-perl `#systools` \
  ubuntu-restricted-extras gimp audacity vlc vlc-plugin-fluidsynth ffmpeg atomicparsley `#media` \
  openjdk-8-jdk icedtea-8-plugin `#openjdk8` \
  openssh-server fail2ban `#daemon` \
  openvpn network-manager-openconnect-gnome network-manager-openvpn-gnome `#network-client` \
  rdesktop freerdp2-x11 xtightvncviewer sshpass qbittorrent wireshark `#netutil` \
  nmap nikto chkrootkit wavemon namebench apache2-utils mailutils `#netutils` \
  iftop iptraf `#netutils` \
  virtualenv python2.7-examples python-pip `#python` \
  build-essential `#build-tools` \
  shellcheck sqlitebrowser yamllint highlight gawk `#dev-tools` \
  lynis pandoc apt-transport-https `#misc` \
  xchat pidgin `#chatapps` \
  oracle-java8-installer `#oracle java8 from ppa` \
  ansible `#automation`
}

# Set vim editor
set_editor () {
  if [[ ! $(readlink /etc/alternatives/editor) == /usr/bin/vim.basic ]]; then
    sudo update-alternatives --set editor /usr/bin/vim.basic
  fi
}

# install pip packages
pip_bits () {
  pip_pkgs=("youtube-dl" "awscli")

  for i in "${pip_pkgs[@]}"; do
    if ! pip show "$i" >/dev/null; then
      pip install $i
    fi
  done
}

# configure lm_sensors
config_sensors () {
  if ! dmesg | grep -i hypervisor; then
    if ! lsmod | grep coretemp; then
      sudo sensors-detect --auto
    fi
  fi
}

# rvm install
install_rvm () {
  if [ ! -d "$HOME"/.rvm ]; then
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    \curl -sSL https://get.rvm.io | bash -s stable --ruby
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

# atom plugins
install_atom_plugins () {
  if [ -f /usr/bin/atom ]; then
    apm_pkgs=(atom-beautify autocomplete-python busy-signal django-templates intentions linter linter-ui-default script script-runner teletype)

    for i in "${apm_pkgs[@]}"; do
      if [ ! -d $HOME/.atom/packages/$i ]; then
        apm install $i
      fi
    done
  fi
}

# vagrant plugins XXX would be better to compare array of whats installed and what needs to be installed
install_vagrant_plugins () {
  if [ -f /usr/bin/vagrant ]; then
    vg_plugins=("berkshelf" "vagrant-berkshelf")

    for i in "${vg_plugins[@]}"; do
      if ! vagrant plugin list | cut -f 1 -d" " | grep -E ^"$i" >/dev/null; then
        vagrant plugin install $i
      fi
    done
  fi
}

# nvm install
install_nvm () {
  if [ ! -d "$HOME"/.nvm ]; then
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
  fi
}


date

START=$(date +%s)

# run all the functions
check_sudo
gsettings_personalizations
set_shell_stuff
oracle_repo
init_etckeeper
apt_update
apt_upgrade
local_installers
install_apt # XXX
set_editor
pip_bits
config_sensors
install_rvm
install_vb_extras
install_atom_plugins
install_vagrant_plugins
install_nvm

END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)
echo "Ran for ${DIFF}s"

date
