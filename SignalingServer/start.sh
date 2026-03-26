#!/bin/bash
set -e

PG_DATA=/data/postgres
REDIS_DIR=/data/redis

# Ensure data directories exist with correct ownership (needed when
# the host mounts an empty volume over /data)
LOG_DIR=/opt/quickdesk/logs

mkdir -p "$PG_DATA" "$REDIS_DIR" "$LOG_DIR"
chown -R postgres:postgres "$PG_DATA" "$LOG_DIR"

# ---- PostgreSQL ----
if [ ! -f "$PG_DATA/PG_VERSION" ]; then
    echo "[quickdesk] Initializing PostgreSQL..."
    gosu postgres /usr/lib/postgresql/15/bin/initdb -D "$PG_DATA" --auth-local=trust --auth-host=md5
    echo "host all all 0.0.0.0/0 md5" >> "$PG_DATA/pg_hba.conf"
    echo "listen_addresses = '127.0.0.1'" >> "$PG_DATA/postgresql.conf"
fi
gosu postgres /usr/lib/postgresql/15/bin/pg_ctl -D "$PG_DATA" -l "$LOG_DIR/postgres.log" start
sleep 2

# Create user and database if needed
gosu postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER:-quickdesk}'" | grep -q 1 || \
    gosu postgres psql -c "CREATE USER ${DB_USER:-quickdesk} WITH PASSWORD '${DB_PASSWORD:-quickdesk123}';"
gosu postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME:-quickdesk}'" | grep -q 1 || \
    gosu postgres psql -c "CREATE DATABASE ${DB_NAME:-quickdesk} OWNER ${DB_USER:-quickdesk};"

# ---- Redis ----
echo "[quickdesk] Starting Redis..."
redis-server --daemonize yes --dir "$REDIS_DIR" --appendonly yes --bind 127.0.0.1

# ---- Signaling Server ----
echo "[quickdesk] Starting signaling server..."
cd /opt/quickdesk
exec ./signaling
