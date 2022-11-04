alias ans-cron='ansible-playbook -i hosts site.yml --diff --start-at-task="cron; git clone --depth 1 invadelabs.com/cron-invadelabs"'
alias ans-view='ansible-vault view --vault-password-file ~/vault-pass'
alias fix-gpg='export GPG_TTY=$(tty)'
alias git-check='git branch; git status; git diff'
alias git-pers="git config --global user.email 'drewderivative@gmail.com'; export GPGKEY=CA521CE38DD9D8E586AD18607A27C99359698874"
alias git-reset='git fetch origin; git reset --hard origin/master'
alias gh-pr="gh pr create"
alias glab-mr='glab mr create -f -a drew -y --remove-source-branch --squash-before-merge'
alias mnt-d='sudo mount -t cifs -o username=drew,uid=1000,gid=1000 //192.168.1.125/share /mnt/share'
alias rdesktop="rdesktop -g 1280x720 -r clipboard:CLIPBOARD -r disk:share=$HOME"
alias ssh_apt_old='_ssh_apt() { ssh "$1" "sudo apt-get update && sudo apt-get -qy dist-upgrade";}; _ssh_apt'
alias ssh_apt='_ssh_apt() { if [ $(uname) == "Linux" ]; then OPENER=xdg-open; else OPENER=open; fi; ssh "$1" "sudo apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get -qy dist-upgrade"; $OPENER "https://drew-serv.nm1.invadelabs.com/nagios/cgi-bin/cmd.cgi?cmd_typ=7&host=$1&service=Check+Apt&force_check"; }; _ssh_apt'
alias ssh_dnf='_ssh_dnf() { ssh "$1" "sudo dnf -y upgrade";}; _ssh_dnf'
alias sshfs_drew='sshfs 192.168.1.125:/srv $HOME/drewserv'
alias tfa="terraform apply current.plan"
alias tfi='terraform init'
alias tfp="terraform plan -out=current.plan"
alias xclip="xclip -selection clipboard"
