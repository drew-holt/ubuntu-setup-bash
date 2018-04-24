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
  if ! sudo grep $USER /etc/sudoers; then
    echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
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

    # set favorite apps in launcher
    gsettings set org.gnome.shell favorite-apps "['google-chrome.desktop', 'org.gnome.Nautilus.desktop', \
    'org.gnome.Terminal.desktop', 'libreoffice-startcenter.desktop', 'sqlitebrowser.desktop', \
    'qBittorrent.desktop', 'audacity.desktop', 'atom.desktop', 'skypeforlinux.desktop', \
    'org.gnome.baobab.desktop', 'keepass2.desktop', 'slack.desktop', 'vlc.desktop', \
    'xchat.desktop', 'wireshark.desktop', 'virtualbox.desktop']"

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
alias xclip="xclip -selection clipboard"
alias rdesktop="rdesktop -g 1280x720 -r clipboard:CLIPBOARD -r disk:share=/home/$USER"
alias get_ip='_get_ip() { VBoxManage guestproperty get "$1" "/VirtualBox/GuestInfo/Net/1/V4/IP";}; _get_ip'
EOF
  fi
}

## disable popularity-contest XXX how dpkg-reconifgure with debconf selection non-interactively
# echo debconf popularity-contest/participate select false | sudo debconf-set-selections
# sudo dpkg-reconfigure popularity-contest

# oracle 8, google chrome, keybase, skype, slack, atom, insync, docker
extra_repos () {
  APT_DIR="/etc/apt/sources.list.d"
  if [ ! -f "$APT_DIR"/webupd8team-ubuntu-java-artful.list ]; then
    sudo add-apt-repository -y ppa:webupd8team/java
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
  fi

  if [ ! -f "$APT_DIR"/google-chrome.list ]; then
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee "$APT_DIR"/google-chrome.list
  fi

  if [ ! -f "$APT_DIR"/keybase.list ]; then
    wget -q -O - https://keybase.io/docs/server_security/code_signing_key.asc | sudo apt-key add -
    echo "deb http://prerelease.keybase.io/deb stable main" | sudo tee "$APT_DIR"/keybase.list
  fi

  if [ ! -f "$APT_DIR"/skype-stable.list ]; then
    wget -O - https://repo.skype.com/data/SKYPE-GPG-KEY | sudo apt-key add -
    echo "deb [arch=amd64] https://repo.skype.com/deb stable main" | sudo tee "$APT_DIR"/skype-stable.list
  fi

  if [ ! -f "$APT_DIR"/slack.list ]; then
    wget -O - https://packagecloud.io/slacktechnologies/slack/gpgkey | sudo apt-key add -
    echo "deb https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" | sudo tee "$APT_DIR"/slack.list
  fi

  if [ ! -f "$APT_DIR"/atom.list ]; then
    wget -O - https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
    echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" | sudo tee "$APT_DIR"/atom.list
  fi

  if [ ! -f "$APT_DIR"/insync.list ]; then
    wget -O - https://d2t3ff60b2tol4.cloudfront.net/services@insynchq.com.gpg.key | sudo apt-key add -
    echo "deb http://apt.insynchq.com/ubuntu $(lsb_release -cs) non-free" | sudo tee "$APT_DIR"/insync.list
  fi

  if ! grep docker /etc/apt/sources.list; then
    wget -O - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
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

# update repo cache if it's been longer than 2 hours else update for first boot
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

# install etckeeper first and initialize it
init_etckeeper () {
  if [ ! -d /etc/.git ]; then
    wait_apt; sudo apt-get install -qy etckeeper

    # set github here
    git config --global user.name "Drew Holt"
    git config --global user.email "drewderivative@gmail.com"

    sudo etckeeper init
    sudo find /etc/.git -type d -exec chmod 750 {} \;
    sudo find /etc/.git -type d -exec chgrp adm {} \;
  fi
}

# dist-upgrade if upgrades are available
apt_upgrade () {
  if [ ! "$(/usr/lib/update-notifier/apt-check 2>&1 | cut -d ';' -f 1)" == "0" ]; then
    wait_apt; sudo apt-get -qy dist-upgrade
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
  iftop iptraf sshfs `#netutils` \
  virtualenv python2.7-examples python-pip `#python` \
  build-essential `#build-tools` \
  shellcheck sqlitebrowser yamllint highlight gawk `#dev-tools` \
  lynis pandoc apt-transport-https `#misc` \
  xchat pidgin `#chatapps` \
  ansible `#automation` \
  oracle-java8-installer google-chrome-stable keybase `#extra repos` \
  skypeforlinux slack-desktop atom insync docker-ce `#extra repos`
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

add_docker_user () {
  if ! id -nG $USER | grep docker; then
    sudo usermod -aG docker $USER
  fi
}

# rvm install
install_rvm () {
  if [ ! -d "$HOME"/.rvm ]; then
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    \curl -sSL https://get.rvm.io | bash -s stable --ruby
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
extra_repos
apt_update
init_etckeeper
apt_upgrade
install_apt
set_editor
pip_bits
config_sensors
add_docker_user
install_rvm
install_atom_plugins
install_nvm

END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)
echo "Ran for ${DIFF}s"

date
