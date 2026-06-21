# mni.ac

usage

1. `sudo loginctl enable-linger $(whoami)`
1. `git clone`
1. `stow --dotfiles home`
1. `sudo ln -sf ~/etc/systemd/system/compose-app@.service /etc/systemd/system`
1. for dir in `~/opt/compose/` `cp env.example .env` and modify as needed
1. for dir in `~/opt/compose/` `~/opt/scripts/systemd-enable-service.sh $dir`
1. `cp ~/.config/restic/{env.example,env}` and modify as needed
1. `openssl rand -base64 48 > ~/.config/restic/password`
1. install and configure syncthing

`zuo_shou`

1. [on dev server] `git clone zuo_shou && cd zuo_shou`
1. [on dev server] edit `.env` to set `DEPLOY_PATH='hostname.tld:~/opt/apps/zuo_shou`
1. [on dev server] `make deploy-prod`
1. `stow zuo_shou`
1. `systemctl --user daemon-reload && systemctl --user start zuo_shou.service`
