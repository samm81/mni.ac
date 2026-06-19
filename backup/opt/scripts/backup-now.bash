#!/usr/bin/env bash
set -euo pipefail

#STAMP="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
#OUTDIR="$HOME/opt/backups/postgres"
#DUMPFILE="$OUTDIR/postgres-all-$STAMP.sql.gz"
#
#mkdir -p "$OUTDIR"
#
## Dump Postgres from the Docker container
#docker exec coredb-postgres-1 pg_dumpall -U postgres | gzip -9 > "$DUMPFILE"
#
## Keep only 7 days of raw dumps locally
#find "$OUTDIR" -type f -name 'postgres-all-*.sql.gz' -mtime +7 -delete

# Backup to restic
restic backup \
  "${HOME}/opt" \
  --exclude "${HOME}/opt/**/node_modules" \
  --exclude "${HOME}/opt/**/.cache" \
  --exclude "${HOME}/opt/**/tmp" \
  --exclude "${HOME}/opt/**/cache" \
  --exclude "${HOME}/opt/state/beszel" \
  --exclude "${HOME}/opt/state/caddy" \
  "${HOME}/etc" \
  "${HOME}/.local/state" \
  --exclude-caches

# Retention
restic forget --prune \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6
