alias xclip="xclip -selection clipboard"
alias rdesktop="rdesktop -g 1280x720 -r clipboard:CLIPBOARD -r disk:share=$HOME"
alias get_ip='_get_ip() { VBoxManage guestproperty get "$1" "/VirtualBox/GuestInfo/Net/1/V4/IP";}; _get_ip'
alias ans-cron='ansible-playbook -i hosts site.yml --diff --start-at-task="cron; git clone --depth 1 invadelabs.com/cron-invadelabs"'
alias git-reset='git fetch origin; git reset --hard origin/master'
alias git-check='git branch; git status; git diff'
alias git-pers="git config --global user.email 'drewderivative@gmail.com'; export GPGKEY=CA521CE38DD9D8E586AD18607A27C99359698874"
alias gpg-kill="kill $(ps -ef | grep -E [g]pg-agent | awk -F" " '{ print $2 }') && gpg-agent --daemon"
alias mnt-d='sudo mount -t cifs -o username=drew,uid=1000,gid=1000 //192.168.1.125/share /mnt/share'
alias hub-pr="hub pull-request -o --no-edit"
alias tfi='rm -rf .terraform/modules/* && terraform init'
alias tfp="terraform plan -out=current.plan"
alias tfa="terraform apply current.plan"
alias ssh_apt='_ssh_apt() { ssh "$1" "sudo apt-get update && sudo apt-get -qy dist-upgrade";}; _ssh_apt'
alias ssh_dnf='_ssh_dnf() { ssh "$1" "sudo dnf -y upgrade";}; _ssh_dnf'
alias sshfs_drew='sshfs 192.168.1.125:/srv $HOME/drewserv'
