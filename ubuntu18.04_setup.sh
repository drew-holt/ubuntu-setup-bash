#!/bin/bash
# Drew Holt <drew@invadelabs.com>
# script to setup newly installed local environment in ubuntu 18.04
#
# shellcheck disable=SC1090,SC2086,SC2119,SC2016,SC2120
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2086: Double quote to prevent globbing and word splitting.
# SC2119: Use set_shell_stuff "$@" if function's $1 should mean script's $1.
# SC2016: Expressions don't expand in single quotes, use double quotes for that.
# SC2120: set_aliases references arguments, but none are ever passed.

set -x # all executed commands are printed to the terminal
set -e # exit if any subcommand or pipeline returns a non-zero status

# passwordless sudo for local box
check_sudo () {
  if ! sudo grep $USER /etc/sudoers; then
    echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
  fi
}

# gnome3 peronalizations and prefrences
gsettings_personalizations () {
  # dl background
  if [ ! -f $HOME/Pictures/vector.jpg ]; then
    wget -O $HOME/Pictures/vector.jpg https://imgur.com/download/nhUeOpI
  fi

  # settings_list=$(gsettings list-recursively) XXX check these everytime
  if [[ ! $(gsettings get org.gnome.desktop.interface clock-format) == "'12h'" ]]; then
    # set 12 hour time
    gsettings set org.gnome.desktop.interface clock-format 12h

    # set natural scrolling on mouse not touchpad, GUI under 'Settings > Mouse'
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

    # set to false when gaming on touch pad, true when not gaming
    # gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false

    # task bar settings
    gsettings set org.gnome.desktop.interface clock-show-seconds true
    gsettings set org.gnome.desktop.interface clock-show-date true
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.calendar show-weekdate true

    # disable screen rotation
    gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock true

    # sleep after 1 hour, power button suspends
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
    gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

    # set timeout 'Blank screen' to 15min
    gsettings set org.gnome.desktop.session idle-delay uint32 900

    # switch alt+tab to windows, not applications. GUI under 'Settings > Keyboard'
    gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward  "['<Alt><Shift>Tab']"

    # set favorite apps in launcher
    gsettings set org.gnome.shell favorite-apps "['google-chrome.desktop', \
                                                  'firefox.desktop', \
                                                  'org.gnome.Nautilus.desktop', \
                                                  'org.gnome.Terminal.desktop', \
                                                  'libreoffice-startcenter.desktop', \
                                                  'sqlitebrowser.desktop', \
                                                  'qbittorrent.desktop', \
                                                  'audacity.desktop', \
                                                  'atom.desktop', \
                                                  'skype_skypeforlinux.desktop', \
                                                  'org.gnome.baobab.desktop', \
                                                  'keepass2.desktop', \
                                                  'slack.desktop', \
                                                  'vlc.desktop', \
                                                  'xchat.desktop', \
                                                  'wireshark.desktop', \
                                                  'virtualbox.desktop']"

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

    # remove terminal menubar
    gsettings set org.gnome.Terminal.Legacy.Settings default-show-menubar false

    # set background, screensaver, desktop colors
    gsettings set org.gnome.desktop.screensaver primary-color '#000000000000'
    gsettings set org.gnome.desktop.screensaver secondary-color '#000000000000'
    gsettings set org.gnome.desktop.screensaver picture-uri "file://$HOME/Pictures/vector.jpg"
    gsettings set org.gnome.ControlCenter last-panel 'background'
    gsettings set org.gnome.desktop.background secondary-color '#000000000000'
    gsettings set org.gnome.desktop.background primary-color '#000000000000'
    gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/vector.jpg"

    # enable Night Light
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
  fi

  # setup default apps
  if [ ! -f $HOME/.config/mimeapps.list ]; then
    wget -O $HOME/.config/mimeapps.list https://raw.githubusercontent.com/drew-holt/ubuntu-setup-bash/master/mimeapps.list
  fi

  # remove clutter
  folders_rm=(Documents Music Public Templates Videos)
  for i in "${folders_rm[@]}"; do
    if [ -d $i ]; then
      rmdir $i
    fi
  done

  folders_mk=(/mnt/hdd /mnt/share "$HOME"/drewserv)
  for i in "${folders_mk[@]}"; do
    if [ ! -d $i ]; then
      sudo mkdir $i
    fi
  done

  if [ -f "$HOME"/examples.desktop ]; then
    rm "$HOME"/examples.desktop
  fi
}

# set env and aliases XXX check these everytime
set_shell_stuff () {
  if ! grep bashrc "$HOME"/.bash_profile; then
    cat <<EOF >> $HOME/.bash_profile
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
EOF
  fi

  if ! grep .bash_aliases "$HOME"/.bashrc; then
    echo "No refrence to .bash_aliases in .bashrc - bailing"
    exit 1
  fi

  wget -O $HOME/.bash_aliases https://raw.githubusercontent.com/drew-holt/ubuntu-setup-bash/master/.bash_aliases
}

sysctl_cus () {
  if [ ! -f /etc/sysctl.d/99-vm.swapiness.conf ]; then
    echo "vm.swappiness = 0" | sudo tee /etc/sysctl.d/99-vm.swapiness.conf
    sudo systemctl restart procps
  fi
}

# oracle 8, google chrome, keybase, skype, slack, atom, insync, docker
extra_repos () {
  APT_DIR="/etc/apt/sources.list.d"

  if [ ! -f "$APT_DIR"/webupd8team-ubuntu-java-"$(lsb_release -cs)".list ]; then
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

  if [ ! -f "$APT_DIR"/atom.list ]; then
    wget -O - https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
    echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" | sudo tee "$APT_DIR"/atom.list
  fi

  if [ ! -f "$APT_DIR"/insync.list ]; then
    wget -O - https://d2t3ff60b2tol4.cloudfront.net/services@insynchq.com.gpg.key | sudo apt-key add -
    echo "deb http://apt.insynchq.com/ubuntu $(lsb_release -cs) non-free" | sudo tee "$APT_DIR"/insync.list
  fi

  # docker use repos in artful, bionic use snaps
  # if [ "$(lsb_release -cs)" == "artful" ]; then
  #   if ! grep docker /etc/apt/sources.list; then
  #     wget -O - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  #     sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  #   fi
  # fi
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
    if ! find /var/cache/apt/pkgcache.bin -mmin -120; then
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
    git config --global color.status auto
    git config --global color.branch auto
    git config --global color.interactive auto
    git config --global color.diff auto

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
  echo postfix postfix/mailname string "$HOSTNAME".local | sudo debconf-set-selections
  echo postfix postfix/main_mailer_type string 'Local only' | sudo debconf-set-selections

  # install all the things
  wait_apt;
  DEBIAN_FRONTEND=noninteractive `#no prompting` \
    sudo apt-get install -qy \
    gnome-shell-extension-top-icons-plus gnome-shell-extension-dashtodock `#gui` \
    gnome-shell-extension-system-monitor `#gui` \
    keepass2 kpcli xdotool synergy gnome-tweak-tool chrome-gnome-shell xclip gtk-recordmydesktop `#tools` \
    acpi vim vim-scripts vim-runtime vim-doc curl xd libguestfs-tools ecryptfs-utils encfs `#systools` \
    lm-sensors p7zip-full exfat-utils exfat-fuse libimage-exiftool-perl screen `#systools` \
    ubuntu-restricted-extras gimp audacity vlc vlc-plugin-fluidsynth ffmpeg atomicparsley `#media` \
    openjdk-8-jdk icedtea-8-plugin `#openjdk8` \
    openssh-server fail2ban `#daemon` \
    openvpn network-manager-openconnect-gnome network-manager-openvpn-gnome `#network-client` \
    rdesktop freerdp2-x11 xtightvncviewer sshpass qbittorrent wireshark `#netutil` \
    nmap nikto chkrootkit wavemon namebench apache2-utils mailutils `#netutils` \
    iftop iptraf sshfs cifs-utils ethtool `#netutils` \
    virtualenv python2.7-examples python-pip python3-pip `#python` \
    build-essential `#build-tools` \
    shellcheck sqlitebrowser yamllint highlight gawk php-cli tidy jq gitk `#dev-tools` \
    libreadline-dev zlib1g-dev libffi-dev gcc-6 g++-6 libssl1.0-dev `# dev-tools rbenv` \
    lynis pandoc apt-transport-https snapd `#misc` \
    xchat pidgin `#chatapps` \
    ansible `#automation` \
    oracle-java8-installer google-chrome-stable keybase `#extra repos` \
    atom insync `# extra repos` \
    docker.io
}

install_snaps () {
  snap_pkgs=(hub kubectl skype slack)
  for i in "${snap_pkgs[@]}"; do
    if ! snap list | grep $i; then
      sudo snap install $i --classic
    fi
  done
}

# Set vim editor
set_editor () {
  if [[ ! $(readlink /etc/alternatives/editor) == /usr/bin/vim.basic ]]; then
    sudo update-alternatives --set editor /usr/bin/vim.basic
  fi
}

# configure dash to dock XXX check these everytime
gui_tweaks () {
  if [ "$(gsettings get org.gnome.shell enabled-extensions)" == "@as []" ]; then
    gnome-shell --replace &

    gsettings set org.gnome.shell enabled-extensions "['dash-to-dock@micxgx.gmail.com', 'TopIcons@phocean.net', 'system-monitor@paradoxxx.zero.gmail.com']"

    # dash to dock
    gsettings set org.gnome.shell.extensions.dash-to-dock preferred-monitor 0
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false

    # topicons
    gsettings set org.gnome.shell.extensions.topicons icon-size 24
    gsettings set org.gnome.shell.extensions.topicons tray-pos 'right'
    gsettings set org.gnome.shell.extensions.topicons icon-brightness 0.0
    gsettings set org.gnome.shell.extensions.topicons icon-saturation 0.40000000000000002
    gsettings set org.gnome.shell.extensions.topicons icon-contrast 0.0
    gsettings set org.gnome.shell.extensions.topicons icon-opacity 220
    gsettings set org.gnome.shell.extensions.topicons tray-order 1
    gsettings set org.gnome.shell.extensions.topicons icon-spacing 12
  fi
}

# install pip packages
pip_bits () {
  pip_pkgs=(youtube-dl awscli pylint pycodestyle ansible-lint docker-py httpstat)
  pip_installed=$(pip list --format=legacy | cut -f1 -d" " | xargs printf %s" ")

  for i in "${pip_pkgs[@]}"; do
    if ! echo $pip_installed | grep $i; then
      pip3 install --user $i
    fi
  done
}

# install pip packages
pip3_bits () {
  pip3_pkgs=(ansible)
  pip3_installed=$(pip list --format=legacy | cut -f1 -d" " | xargs printf %s" ")

  for i in "${pip3_pkgs[@]}"; do
    if ! echo $pip3_installed | grep $i; then
      pip install --user $i
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
  if ! getent group docker; then
    sudo groupadd docker
  fi

  if ! id -nG $USER | grep docker; then
    sudo usermod -aG docker $USER
  fi
}

# atom plugins
install_atom_plugins () {
  if [ -f "$(command -v atom)" ]; then
    apm_pkgs=( \
    atom-beautify \
    autocomplete-python \
    busy-signal \
    django-templates \
    emmet \
    git-plus \
    file-icons \
    intentions \
    language-ansible \
    language-chef \
    language-docker \
    language-hcl \
    language-groovy \
    linter \
    linter-ansible-linting \
    linter-ansible-syntax \
    linter-cookstyle \
    linter-docker \
    linter-htmllint \
    linter-js-yaml \
    linter-jsonlint \
    linter-markdown \
    linter-php \
    linter-pycodestyle \
    linter-pylint \
    linter-rubocop \
    linter-ruby \
    linter-travis-lint \
    linter-terraform-syntax \
    language-terraform \
    linter-ui-default \
    linter-vagrant-validate \
    linter-tidy \
    minimap \
    remove-whitespace \
    script \
    script-runner \
    teletype \
    )

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

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    nvm install 9
  fi

  source $HOME/.bashrc && echo $PATH

  npm_pkgs=(htmllint \
            html-validator \
            jsonlint \
            dockerlint \
            lighthouse)
  npm_installed=$(npm list -g)
  for i in "${npm_pkgs[@]}"; do
    if ! echo $npm_installed | grep $i; then
      npm install -g $i
    fi
  done
}

# rbenv install
install_rbenv () {
  if [ ! -d "$HOME/.rbenv" ]; then
    git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> $HOME/.bash_profile
    echo 'eval "$(rbenv init -)"' >> $HOME/.bash_profile
    $HOME/.rbenv/bin/rbenv init -
    source $HOME/.bash_profile || true

    mkdir -p "$(rbenv root)"/plugins
    git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

    rbenv install 2.5.5
    rbenv install 2.5.1
    rbenv global 2.5.5
  fi

  # switched to rbenv, for rvm use:
  # if [ ! -d "$HOME"/.rvm ]; then
  #   case "$(lsb_release -cs)" in
  #     bionic)
  #       IP="$(python -c 'import socket; print socket.gethostbyname("keys.gnupg.net")')"
  #       gpg --keyserver hkp://$IP --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  #       ;;
  #     *)
  #       gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  #   esac
  #   \curl -sSL https://get.rvm.io | bash -s stable --ruby
  #   source $HOME/.rvm/scripts/rvm
  # fi

  gem_list=(cookstyle \
            travis \
            mdl \
            gitlab \
            rubocop \
            bundler \
            test-kitchen)
  gem_installed=$(gem list | cut -f1 -d" " | xargs printf %s" ")

  for i in "${gem_list[@]}"; do
    if ! echo $gem_installed | grep $i; then
      gem install $i
    fi
  done
}

hashicorp_tools () {
  if [ ! -f /usr/local/bin/packer ]; then
    curl -sS -o /tmp/packer_1.2.4_linux_amd64.zip https://releases.hashicorp.com/packer/1.2.4/packer_1.2.4_linux_amd64.zip
    sudo unzip -d /usr/local/bin /tmp/packer_1.2.4_linux_amd64.zip
  fi

  if [ ! -f /usr/local/bin/terraform ]; then
    curl -sS -o /tmp/terraform_0.11.14_linux_amd64.zip https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
    sudo unzip -d /usr/local/bin /tmp/terraform_0.11.14_linux_amd64.zip
  fi
}

chefvm_install () {
  if [ ! -d $HOME/.chefvm ]; then
    git clone git://github.com/trobrock/chefvm.git ~/.chefvm
  fi
}

cerebro_install () {
  if [ ! -d $HOME/Desktop/cerebro-0.9.0 ]; then
    wget -O $HOME/Desktop/cerebro-0.9.0.tgz https://github.com/lmenezes/cerebro/releases/download/v0.9.0/cerebro-0.9.0.tgz
    tar xvf $HOME/Desktop/cerebro-0.9.0.tgz -C $HOME/Desktop
    rm $HOME/Desktop/cerebro-0.9.0.tgz
  fi
}

tfenv_install () {
  echo "install tfenv for terraform versioning"
  echo "https://github.com/tfutils/tfenv"
}

date

START=$(date +%s)

# run all the functions
check_sudo
gsettings_personalizations
set_shell_stuff
sysctl_cus
extra_repos
apt_update
init_etckeeper
apt_upgrade
install_apt
install_snaps
set_editor
gui_tweaks
pip_bits
pip3_bits
config_sensors
add_docker_user
install_atom_plugins
install_nvm
install_rbenv
hashicorp_tools
chefvm_install
cerebro_install
tfenv_install

END=$(date +%s)
DIFF=$(echo "$END - $START" | bc)
echo "Ran for ${DIFF}s"

date
