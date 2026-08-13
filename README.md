# mni.ac

a few GNU Stow packages for a single-user server.

usage

1. `sudo loginctl enable-linger "$USER"`
1. `git clone git@github.com:samm81/mni.ac.git "$HOME/mni.ac" && cd "$HOME/mni.ac"`
1. `stow --dotfiles base backup`
1. `docker network inspect ingress >/dev/null 2>&1 || docker network create ingress`
1. `cp ~/opt/compose/caddy/example.env ~/opt/compose/caddy/.env` and modify as needed
1. `cp ~/opt/compose/beszel/{example.env.beszel,.env.beszel}` and modify as needed
1. `cp ~/opt/compose/beszel/{example.env.beszel_agent,.env.beszel_agent}` and modify as needed
1. `openssl rand -base64 48 > ~/.config/restic/password`
1. `cp ~/.config/restic/{env.example,env}` and modify as needed
1. `systemctl --user daemon-reload`
1. `systemctl --user enable --now compose-app@caddy.service compose-app@beszel.service vps-backup.timer`
1. install and configure syncthing

for optional packages, run `stow --dotfiles <package>` from `~/mni.ac`. follow the package instructions before enabling its service.

`postgres`

1. after postgres starts, run `~/opt/compose/postgres/configure.bash`

`zuo_shou`

1. [on dev server] `git clone zuo_shou && cd zuo_shou`
1. [on dev server] set `DEPLOY_PATH='hostname.tld:~/opt/apps/zuo_shou'` in `.env`
1. [on dev server] `make deploy-prod`
1. `cd "$HOME/mni.ac" && stow --dotfiles zuo_shou`
1. `systemctl --user daemon-reload && systemctl --user enable --now zuo_shou.service`

`pesterbot2.0`

same as `zuo_shou`, with `postgres` configured first (and an `.env` file).
