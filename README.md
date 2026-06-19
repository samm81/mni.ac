# mni.ac

usage

1. `git clone`
1. `stow --dotfiles home`
1. `sudo ln -sf ~/etc/systemd/system/compose-app@.service /etc/systemd/system`
1. for dir in `~/opt/compose/` `cp env.example .env` and modify as needed
1. for dir in `~/opt/compose/` `~/opt/scripts/systemd-enable-service.sh $dir`
1. `cp ~/.config/restic/{env.example,env}` and modify as needed
1. `openssl rand -base64 48 > ~/.config/restic/password`
1. install and configure syncthing
