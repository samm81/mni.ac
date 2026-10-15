# mni.ac

a few gnu stow packages for a single-user server

## usage

1. install `stow`
1. install Docker Engine with the Compose plugin
1. `sudo loginctl enable-linger "$USER"`
1. `git clone git@github.com:samm81/${REPO} "${HOME}/${REPO_ROOT}" && cd "${HOME}/${REPO_ROOT}"`
1. `stow --dotfiles --no-folding 00-base 00-beszel 00-uptime-kuma`
1. `docker network inspect ingress >/dev/null 2>&1 || docker network create ingress`
1. `cp ~/opt/compose/caddy/example.env ~/opt/compose/caddy/.env` and modify as needed
1. `cp ~/opt/compose/beszel/{example.env.beszel,.env.beszel}` and modify as needed
1. `cp ~/opt/compose/beszel/{example.env.beszel_agent,.env.beszel_agent}` and modify as needed
1. install `restic`
1. `stow --dotfiles 10-backup`
1. `openssl rand -base64 48 > ~/.config/restic/password`
1. `cp ~/.config/restic/{env.example,env}` and modify as needed
1. `systemctl --user daemon-reload`
1. `systemctl --user enable --now compose-app@caddy.service compose-app@beszel.service compose-app@uptime-kuma.service vps-backup.timer`

## optional packages

generally: run `stow --dotfiles --no-folding <package>`. follow the package instructions before enabling its service.

### `claw`

the package sets `CLAW_SRV` in `~/opt/compose/caddy/.env.d/99-claw.env`.
set a different path in `~/opt/compose/caddy/.env` if needed.

### `srv`

stow `99-srv` to serve `~/opt/srv` at `a.${DOMAIN}`.

### `cockpit` (recommended)

1. [install and configure `cockpit`](https://cockpit-project.org/running.html)
1. `stow --no-folding 30-cockpit`
1. `cp 30-cockpit-system/etc/cockpit/cockpit.example.conf 30-cockpit-system/etc/cockpit/cockpit.conf`
1. edit `30-cockpit-system/etc/cockpit/cockpit.conf` to replace `${DOMAIN}`
1. `sudo stow --no-folding --target=/ 30-cockpit-system`
1. `sudo systemctl restart cockpit.service`
1. `systemctl --user restart compose-app@caddy.service`

### `syncthing`

1. [install and configure `syncthing`](https://docs.syncthing.net/intro/getting-started.html#getting-started)
1. `stow --dotfiles --no-folding 70-syncthing`
1. `systemctl --user restart compose-app@caddy.service`

### `postgres`

1. after `postgres` starts, run `~/opt/compose/postgres/configure.bash`

### `zuo_shou`

depends on `syncthing`

1. [on dev server] `git clone zuo_shou && cd zuo_shou`
1. [on dev server] set `DEPLOY_PATH='hostname.tld:~/opt/apps/zuo_shou'` in `.env`
1. [on dev server] `make deploy-prod`
1. `cd "$HOME/${REPO_ROOT}" && stow --dotfiles zuo_shou`
1. `systemctl --user daemon-reload && systemctl --user enable --now zuo_shou.service`

### `pesterbot2.0`

depends on `postgres`

same as `zuo_shou`, with an `.env` file

### `timeline-cities`

depends on `syncthing`

same as `zuo_shou` but with an `.env` file and a `.timer` `systemd` unit

## development

`make check` needs `shellcheck`, `shfmt`, `yamllint`, `markdownlint-cli2`,
`prettier`, `docker`, and `stow`.
