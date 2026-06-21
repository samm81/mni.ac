# mni.ac

usage

1. `sudo loginctl enable-linger $(whoami)`
1. `git clone`
1. `stow --dotfiles home`
1. for dir in `~/opt/compose/` `cp env.example .env` and modify as needed
1. `systemctl --user daemon-reload`
1. for dir in `~/opt/compose/` `systemctl --user enable --now compose-app@${dir}.service`
1. `cp ~/.config/restic/{env.example,env}` and modify as needed
1. `openssl rand -base64 48 > ~/.config/restic/password`
1. install and configure syncthing

`zuo_shou`

1. [on dev server] `git clone zuo_shou && cd zuo_shou`
1. [on dev server] edit `.env` to set `DEPLOY_PATH='hostname.tld:~/opt/apps/zuo_shou`
1. [on dev server] `make deploy-prod`
1. `stow zuo_shou`
1. `systemctl --user daemon-reload && systemctl --user enable --now zuo_shou.service`
