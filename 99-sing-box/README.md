# sing-box

the package serves Hysteria2 on UDP port 8443 and VLESS + REALITY on TCP port 8443.

## connecting

`generate-config.bash` creates these connection configs beside `config.json`:

- `hysteria2-outbound.json`
- `vless-reality-outbound.json`
- `mihomo-proxies.yaml`

they contain credentials, so transfer them securely.

for sing-box, add the selected JSON object to the client's `outbounds` and route the desired traffic to its tag.

for Mihomo or a Clash.Meta-compatible client, use `mihomo-proxies.yaml` as a file proxy provider or copy its entries into the client's `proxies` list. for example:

```yaml
proxy-providers:
  mniac:
    type: file
    path: ./mihomo-proxies.yaml
```

add `mni` to a proxy group's `use` list. the rest of either client configuration, such as TUN or local proxy settings and routing rules, depends on how the client should capture and route traffic.

see the sing-box [Hysteria2](https://sing-box.sagernet.org/configuration/outbound/hysteria2/), [VLESS](https://sing-box.sagernet.org/configuration/outbound/vless/), and [TLS/REALITY](https://sing-box.sagernet.org/configuration/shared/tls/) configuration references for other sing-box client options. see the Mihomo [Hysteria2](https://wiki.metacubex.one/en/config/proxies/hysteria2/), [VLESS](https://wiki.metacubex.one/en/config/proxies/vless/), and [proxy provider](https://wiki.metacubex.one/en/config/proxy-providers/content/) references for Mihomo options.
