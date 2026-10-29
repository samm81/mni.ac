#!/usr/bin/env bash
# unofficial strict mode
# note bash<=4.3 chokes on empty arrays with set -o nounset
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://sharats.me/posts/shell-script-best-practices/
set -o errexit
set -o nounset
set -o pipefail

IFS=$'\n\t'
shopt -s nullglob globstar

[[ "${TRACE:-0}" == '1' ]] && set -o xtrace

usage() {
    local filename
    filename="$(basename "$0")"
    printf 'usage: %s\n' "$filename"
    printf '\n'
    printf 'generate the server config and client outbound configs.\n'
    printf 'Caddy must already have issued a certificate for DOMAIN.\n'
    printf 'if CADDY_CERTIFICATE_ISSUER is empty, detect it and save it to .env.\n'
    exit
}

[[ "${1:-}" =~ ^-*h(e(l(p)?)?)?$ ]] && usage

umask 077

directory_script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
file_environment="$directory_script/.env"
template_config="$directory_script/config.example.json"
file_config="$directory_script/config.json"
file_outbound_hysteria2="$directory_script/hysteria2-outbound.json"
file_outbound_vless_reality="$directory_script/vless-reality-outbound.json"
file_proxies_mihomo="$directory_script/mihomo-proxies.yaml"
root_certificates="$HOME/opt/state/caddy/data/caddy/certificates"
image_sing_box='ghcr.io/sagernet/sing-box:latest'

if [[ ! -f $file_environment ]]; then
    printf 'error: missing %s; copy example.env to .env first\n' "$file_environment" >&2
    exit 1
fi

files_output=("$file_config" "$file_outbound_hysteria2" "$file_outbound_vless_reality" "$file_proxies_mihomo")
for file_output in "${files_output[@]}"; do
    if [[ -e $file_output ]]; then
        printf 'error: %s already exists; remove generated configs before generating new credentials\n' "$file_output" >&2
        exit 1
    fi
done

# shellcheck source=/dev/null
source "$file_environment"

if [[ -z ${DOMAIN:-} ]]; then
    printf 'error: DOMAIN is empty in %s\n' "$file_environment" >&2
    exit 1
fi

if ! [[ $DOMAIN =~ ^[a-zA-Z0-9.-]+$ ]]; then
    printf 'error: DOMAIN must contain only letters, numbers, dots, and hyphens\n' >&2
    exit 1
fi

if [[ ! -d $root_certificates ]]; then
    printf 'error: Caddy certificate directory not found: %s\n' "$root_certificates" >&2
    exit 1
fi

environment_set() {
    local name_environment_variable="$1"
    local value_environment_variable="$2"
    local file_temporary

    file_temporary="$(mktemp "$file_environment.XXXXXX")"
    awk -v name="$name_environment_variable" -v value="$value_environment_variable" '
        BEGIN {
            prefix = name "="
            quote = sprintf("%c", 39)
        }
        index($0, prefix) == 1 {
            if (!found) {
                print prefix quote value quote
            }
            found = 1
            next
        }
        { print }
        END {
            if (!found) {
                print prefix quote value quote
            }
        }
    ' "$file_environment" > "$file_temporary"
    mv -- "$file_temporary" "$file_environment"
}

issuer_caddy_certificate="${CADDY_CERTIFICATE_ISSUER:-}"
if [[ -z $issuer_caddy_certificate ]]; then
    paths_certificate=()
    while IFS= read -r path_certificate; do
        if [[ -f ${path_certificate%.crt}.key ]]; then
            paths_certificate+=("$path_certificate")
        fi
    done < <(
        find "$root_certificates" \
            -mindepth 3 -maxdepth 3 \
            -type f -path "*/$DOMAIN/$DOMAIN.crt" -print
    )

    if ((${#paths_certificate[@]} == 0)); then
        printf 'error: no matching Caddy certificate and key found for %s\n' "$DOMAIN" >&2
        exit 1
    fi

    if ((${#paths_certificate[@]} > 1)); then
        printf 'error: multiple Caddy certificate issuers found for %s; set CADDY_CERTIFICATE_ISSUER in %s to one of:\n' \
            "$DOMAIN" "$file_environment" >&2
        for path_certificate in "${paths_certificate[@]}"; do
            path_relative="${path_certificate#"$root_certificates"/}"
            printf '  %s\n' "${path_relative%%/*}" >&2
        done
        exit 1
    fi

    path_relative="${paths_certificate[0]#"$root_certificates"/}"
    issuer_caddy_certificate="${path_relative%%/*}"
    environment_set CADDY_CERTIFICATE_ISSUER "$issuer_caddy_certificate"
fi

directory_certificate="$root_certificates/$issuer_caddy_certificate/$DOMAIN"
if [[ ! -r $directory_certificate/$DOMAIN.crt || ! -r $directory_certificate/$DOMAIN.key ]]; then
    printf 'error: Caddy certificate or key is not readable in %s\n' "$directory_certificate" >&2
    exit 1
fi

password_hysteria2="$(openssl rand -hex 32)"
uuid_user="$(docker run --rm "$image_sing_box" generate uuid)"
keypair_reality="$(docker run --rm "$image_sing_box" generate reality-keypair)"
key_reality_private="$(sed -n 's/^PrivateKey: //p' <<< "$keypair_reality")"
key_reality_public="$(sed -n 's/^PublicKey: //p' <<< "$keypair_reality")"
id_reality_short="$(openssl rand -hex 8)"

if [[ -z $key_reality_private || -z $key_reality_public ]]; then
    printf 'error: could not read the REALITY keypair from sing-box output\n' >&2
    exit 1
fi

config_temporary="$(mktemp "$directory_script/config.json.XXXXXX")"
outbound_hysteria2_temporary="$(mktemp "$directory_script/hysteria2-outbound.json.XXXXXX")"
outbound_vless_reality_temporary="$(mktemp "$directory_script/vless-reality-outbound.json.XXXXXX")"
proxies_mihomo_temporary="$(mktemp "$directory_script/mihomo-proxies.yaml.XXXXXX")"
trap 'rm -f -- "$config_temporary" "$outbound_hysteria2_temporary" "$outbound_vless_reality_temporary" "$proxies_mihomo_temporary"' EXIT

sed \
    -e "s|\"password\": \"generate with: openssl rand -hex 32\"|\"password\": \"$password_hysteria2\"|" \
    -e "s|\"uuid\": \"generate with: docker run --rm ghcr.io/sagernet/sing-box generate uuid\"|\"uuid\": \"$uuid_user\"|" \
    -e "s|\"private_key\": \"generate with: docker run --rm ghcr.io/sagernet/sing-box generate reality-keypair; use PrivateKey output\"|\"private_key\": \"$key_reality_private\"|" \
    -e "s|\"short_id\": \[\"generate with: openssl rand -hex 8\"\]|\"short_id\": [\"$id_reality_short\"]|" \
    -e "s|example.com|$DOMAIN|g" \
    "$template_config" > "$config_temporary"

if grep -q 'generate with:' "$config_temporary"; then
    printf 'error: config template contains an unhandled generation instruction\n' >&2
    exit 1
fi

cat > "$outbound_hysteria2_temporary" << EOF
{
  "type": "hysteria2",
  "tag": "hysteria2-out",
  "server": "$DOMAIN",
  "server_port": 8443,
  "password": "$password_hysteria2",
  "tls": {
    "enabled": true,
    "server_name": "$DOMAIN"
  }
}
EOF

cat > "$outbound_vless_reality_temporary" << EOF
{
  "type": "vless",
  "tag": "vless-reality-out",
  "server": "$DOMAIN",
  "server_port": 8443,
  "uuid": "$uuid_user",
  "flow": "xtls-rprx-vision",
  "network": "tcp",
  "tls": {
    "enabled": true,
    "server_name": "$DOMAIN",
    "reality": {
      "enabled": true,
      "public_key": "$key_reality_public",
      "short_id": "$id_reality_short"
    }
  }
}
EOF

cat > "$proxies_mihomo_temporary" << EOF
proxies:
  - name: 'hysteria2'
    type: hysteria2
    server: '$DOMAIN'
    port: 8443
    password: '$password_hysteria2'
    sni: '$DOMAIN'
    skip-cert-verify: false
    udp: true
  - name: 'vless-reality'
    type: vless
    server: '$DOMAIN'
    port: 8443
    uuid: '$uuid_user'
    flow: xtls-rprx-vision
    network: tcp
    udp: true
    tls: true
    servername: '$DOMAIN'
    client-fingerprint: chrome
    reality-opts:
      public-key: '$key_reality_public'
      short-id: '$id_reality_short'
    encryption: ''
EOF

mv -- "$config_temporary" "$file_config"
mv -- "$outbound_hysteria2_temporary" "$file_outbound_hysteria2"
mv -- "$outbound_vless_reality_temporary" "$file_outbound_vless_reality"
mv -- "$proxies_mihomo_temporary" "$file_proxies_mihomo"
trap - EXIT

printf 'generated %s\n' "$file_config"
printf 'generated %s\n' "$file_outbound_hysteria2"
printf 'generated %s\n' "$file_outbound_vless_reality"
printf 'generated %s\n' "$file_proxies_mihomo"

exit 0
