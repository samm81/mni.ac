### usage

after editing `~/opt/compose/caddy/conf/Caddyfile` or a file in
`~/opt/compose/caddy/conf/sites-enabled/`, run
`systemctl --user restart compose-app@caddy.service`.

to add a host-port proxy, uncomment the example in
`conf/sites-enabled/host-ports.caddy`. replace `example` and `1234`, then
restart caddy.
