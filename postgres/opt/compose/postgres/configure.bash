#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f apps.env ]; then
  echo "missing apps.env"
  exit 1
fi

source apps.env

validate_name() {
  local name="$1"
  if ! [[ "$name" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "Invalid Postgres identifier: $name"
    echo "Use only letters, numbers, and underscores."
    exit 1
  fi
}

escape_sql_literal() {
  # Escape single quotes for SQL string literals.
  printf "%s" "$1" | sed "s/'/''/g"
}

for entry in "${POSTGRES_APPS[@]}"; do
  IFS=':' read -r db user password <<< "$entry"

  validate_name "$db"
  validate_name "$user"

  password_escaped="$(escape_sql_literal "$password")"

  echo "Applying db=$db user=$user"

  docker compose exec -T postgres psql -U postgres -d postgres <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE rolname = '$user'
  ) THEN
    CREATE ROLE "$user" LOGIN PASSWORD '$password_escaped';
  ELSE
    ALTER ROLE "$user" WITH LOGIN PASSWORD '$password_escaped';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE "$db" OWNER "$user"'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = '$db'
)\gexec

ALTER DATABASE "$db" OWNER TO "$user";
GRANT ALL PRIVILEGES ON DATABASE "$db" TO "$user";
SQL

done

echo "Done."
