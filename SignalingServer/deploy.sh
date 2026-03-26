#!/bin/bash
# QuickDesk Signaling Server — one-click deployment script
# Usage: ./deploy.sh [--env /path/to/.env] [--port 8000] [--domain example.com]
#
# This script:
# 1. Builds the Docker image
# 2. Starts the container with the specified .env config file
# 3. Optionally configures Nginx reverse proxy with SSL
#
# All server configuration is managed through a single .env file.
# Copy .env to your own file (e.g. .env.production) and modify as needed.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PORT=8000
DOMAIN=""
CONTAINER_NAME="quickdesk-signaling"
IMAGE_NAME="quickdesk-signaling"
DATA_DIR="/data/quickdesk"
ENV_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --env) ENV_FILE="$2"; shift 2;;
        --port) PORT="$2"; shift 2;;
        --domain) DOMAIN="$2"; shift 2;;
        --data-dir) DATA_DIR="$2"; shift 2;;
        *) echo "Unknown option: $1"; exit 1;;
    esac
done

# Resolve env file: explicit --env > .env.production > .env
if [ -z "$ENV_FILE" ]; then
    if [ -f "$SCRIPT_DIR/.env.production" ]; then
        ENV_FILE="$SCRIPT_DIR/.env.production"
    elif [ -f "$SCRIPT_DIR/.env" ]; then
        ENV_FILE="$SCRIPT_DIR/.env"
    fi
fi

if [ -z "$ENV_FILE" ] || [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: No .env file found."
    echo ""
    echo "Please copy the template and modify it:"
    echo "  cp .env .env.production"
    echo "  vi .env.production"
    echo ""
    echo "Then run:"
    echo "  ./deploy.sh --env .env.production"
    exit 1
fi

# Resolve to absolute path
ENV_FILE="$(cd "$(dirname "$ENV_FILE")" && pwd)/$(basename "$ENV_FILE")"

echo "=========================================="
echo "QuickDesk Signaling Server Deployment"
echo "=========================================="
echo "Port:     $PORT"
echo "Env file: $ENV_FILE"
echo "Domain:   ${DOMAIN:-<none>}"
echo "Data:     $DATA_DIR"
echo ""

# ---- 1. Build Docker image ----
echo "[1/4] Building Docker image..."
docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"

# ---- 2. Stop old container ----
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "[2/4] Stopping old container..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
else
    echo "[2/4] No old container found."
fi

# ---- 3. Start container ----
echo "[3/4] Starting container..."
mkdir -p "$DATA_DIR"

docker run -d \
    --name "$CONTAINER_NAME" \
    --restart=always \
    -p "$PORT:8000" \
    -v "$DATA_DIR:/data" \
    --env-file "$ENV_FILE" \
    "$IMAGE_NAME"

echo "Waiting for server to become healthy..."

MAX_WAIT=60
WAITED=0
HEALTHY=false

while [ $WAITED -lt $MAX_WAIT ]; do
    # Check if container is still running (not exited / restarting)
    STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "missing")
    if [ "$STATUS" = "exited" ] || [ "$STATUS" = "missing" ]; then
        echo ""
        echo "ERROR: Container exited unexpectedly!"
        docker logs --tail 30 "$CONTAINER_NAME"
        exit 1
    fi

    # Check health endpoint
    if curl -sf "http://127.0.0.1:$PORT/health" > /dev/null 2>&1; then
        HEALTHY=true
        break
    fi

    sleep 2
    WAITED=$((WAITED + 2))
    printf "."
done
echo ""

if [ "$HEALTHY" = true ]; then
    echo "Server is healthy and ready."
else
    echo "ERROR: Server did not become healthy within ${MAX_WAIT}s!"
    echo ""
    echo "Container status: $(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)"
    echo "Recent logs:"
    docker logs --tail 50 "$CONTAINER_NAME"
    exit 1
fi

# ---- 4. Nginx reverse proxy (optional) ----
if [ -n "$DOMAIN" ]; then
    echo "[4/4] Configuring Nginx for $DOMAIN..."

    if ! command -v nginx &>/dev/null; then
        echo "Installing Nginx..."
        if command -v yum &>/dev/null; then
            sudo yum install -y nginx
        elif command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y nginx
        fi
    fi

    sudo mkdir -p /etc/nginx/conf.d
    sudo tee /etc/nginx/conf.d/quickdesk.conf > /dev/null << NGINX_EOF
# QuickDesk Signaling Server reverse proxy
# WebSocket-aware with proper long-connection handling

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

upstream quickdesk_signaling {
    server 127.0.0.1:$PORT;
}

server {
    listen 80;
    server_name $DOMAIN;

    client_max_body_size 100M;

    # WebSocket endpoints (long-lived connections)
    # Server sends Ping every 60s; 300s timeout gives ample margin
    location /signal/ {
        proxy_pass http://quickdesk_signaling;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_read_timeout 300s;
        proxy_send_timeout 300s;

        proxy_buffering off;
    }

    # HTTP API and static files
    location / {
        proxy_pass http://quickdesk_signaling;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 30s;
    }
}
NGINX_EOF

    # Ensure nginx.conf includes conf.d directory
    if ! grep -q 'include /etc/nginx/conf.d/\*.conf' /etc/nginx/nginx.conf 2>/dev/null; then
        echo "Adding conf.d include to nginx.conf..."
        sudo sed -i '/^http\s*{/a \    include /etc/nginx/conf.d/*.conf;' /etc/nginx/nginx.conf
    fi

    sudo nginx -t && sudo systemctl restart nginx && sudo systemctl enable nginx
    echo "Nginx configured for $DOMAIN"

    # SSL with certbot
    if command -v certbot &>/dev/null; then
        echo ""
        read -p "Setup HTTPS with Let's Encrypt? (y/N) " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo certbot --nginx -d "$DOMAIN"
        fi
    else
        echo "TIP: Install certbot for HTTPS: sudo yum install -y certbot python3-certbot-nginx"
    fi
else
    echo "[4/4] Skipping Nginx (no --domain specified)."
fi

echo ""
echo "=========================================="
echo "Deployment complete!"
echo "=========================================="
echo ""
echo "  Health check:  curl http://localhost:$PORT/health"
echo "  Admin panel:   http://localhost:$PORT/admin/"
echo "  Logs:          docker logs -f $CONTAINER_NAME"
echo ""
if [ -n "$DOMAIN" ]; then
    echo "  URL:           http://$DOMAIN"
    echo "  WebSocket:     ws://$DOMAIN/signal/:device_id"
fi
echo ""
echo "  To update configuration:"
echo "    1. Edit your .env file"
echo "    2. Re-run: ./deploy.sh --env <your-env-file>"
