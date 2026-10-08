# mni.ac

a few gnu stow packages for a single-user server

usage

1. `sudo loginctl enable-linger "$USER"`
1. `git clone git@github.com:samm81/${REPO} "${HOME}/${REPO_ROOT}" && cd "${HOME}/${REPO_ROOT}"`
1. `stow --dotfiles 00-base`
1. `docker network inspect ingress >/dev/null 2>&1 || docker network create ingress`
1. `cp ~/opt/compose/caddy/example.env ~/opt/compose/caddy/.env` and modify as needed
1. `cp ~/opt/compose/beszel/{example.env.beszel,.env.beszel}` and modify as needed
1. `cp ~/opt/compose/beszel/{example.env.beszel_agent,.env.beszel_agent}` and modify as needed
1. `stow --dotfiles 10-backup`
1. `openssl rand -base64 48 > ~/.config/restic/password`
1. `cp ~/.config/restic/{env.example,env}` and modify as needed
1. `systemctl --user daemon-reload`
1. `systemctl --user enable --now compose-app@caddy.service compose-app@beszel.service compose-app@uptime-kuma.service vps-backup.timer`
1. [install and configure `syncthing`](https://docs.syncthing.net/intro/getting-started.html#getting-started)
1. [install and configure `cockpit`](https://cockpit-project.org/running.html) && `stow --dotfiles --no-folding 30-cockpit`

for optional packages (`99-*` packages), run `stow --dotfiles <package>` from `~/${REPO_ROOT}`. follow the package instructions before enabling its service.

`postgres`

1. after `postgres` starts, run `~/opt/compose/postgres/configure.bash`

`zuo_shou`

1. [on dev server] `git clone zuo_shou && cd zuo_shou`
1. [on dev server] set `DEPLOY_PATH='hostname.tld:~/opt/apps/zuo_shou'` in `.env`
1. [on dev server] `make deploy-prod`
1. `cd "$HOME/${REPO_ROOT}" && stow --dotfiles zuo_shou`
1. `systemctl --user daemon-reload && systemctl --user enable --now zuo_shou.service`

`pesterbot2.0`

same as `zuo_shou`, with `postgres` configured first and a `.env` file

`timeline-cities`

same as `zuo_shou` but with a `.env` file and a `.timer` `systemd` unit
