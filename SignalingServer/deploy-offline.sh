#!/bin/bash
# QuickDesk Signaling Server — deploy from offline Docker image
# Usage: ./deploy-offline.sh <image.tar.gz> [--port PORT] [--domain DOMAIN]
#
# Download the image tar from GitHub Actions artifacts or Releases,
# then use this script to load and deploy without network access.
#
# Examples:
#   ./deploy-offline.sh quickdesk-signaling-image.tar.gz
#   ./deploy-offline.sh quickdesk-signaling-image.tar.gz --port 9000
#   ./deploy-offline.sh quickdesk-signaling-image.tar.gz --domain example.com

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_TAR=""
PORT=""
DOMAIN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --port)   PORT="$2"; shift 2;;
        --domain) DOMAIN="$2"; shift 2;;
        -h|--help)
            echo "Usage: $0 <image.tar.gz> [--port PORT] [--domain DOMAIN]"
            echo ""
            echo "  image.tar.gz  Path to the Docker image archive"
            echo "  --port        Host port (default: SERVER_PORT from .env, or 8000)"
            echo "  --domain      Configure Nginx reverse proxy + optional SSL"
            exit 0;;
        -*)
            echo "Unknown option: $1"; exit 1;;
        *)
            IMAGE_TAR="$1"; shift;;
    esac
done

if [ -z "$IMAGE_TAR" ]; then
    echo "ERROR: Please provide the path to a Docker image .tar.gz file."
    echo ""
    echo "Usage: $0 <image.tar.gz> [--port PORT] [--domain DOMAIN]"
    echo ""
    echo "You can download the image from:"
    echo "  - GitHub Actions → SignalingServer Docker → Artifacts"
    echo "  - GitHub Releases (for tagged versions)"
    exit 1
fi

if [ ! -f "$IMAGE_TAR" ]; then
    echo "ERROR: File not found: $IMAGE_TAR"
    exit 1
fi

# ---- .env check ----
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "No .env file found."
        echo ""
        echo "Creating .env from .env.example — please review and edit it:"
        cp .env.example .env
        echo "  vim .env"
        echo ""
        echo "Then re-run: $0 $IMAGE_TAR"
        exit 1
    else
        echo "ERROR: Neither .env nor .env.example found."
        exit 1
    fi
fi

if [ -z "$PORT" ]; then
    PORT=$(grep -E '^SERVER_PORT=' .env 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
    PORT="${PORT:-8000}"
fi

echo "=========================================="
echo " QuickDesk Signaling Server (Offline Deploy)"
echo "=========================================="
echo "Image:    $IMAGE_TAR"
echo "Port:     $PORT"
echo "Domain:   ${DOMAIN:-<none>}"
echo ""

export SERVER_PORT="$PORT"

# ---- 1. Load image ----
echo "[1/3] Loading Docker image from $IMAGE_TAR ..."
LOADED_OUTPUT=$(docker load -i "$IMAGE_TAR" 2>&1)
echo "$LOADED_OUTPUT"

LOADED_IMAGE=$(echo "$LOADED_OUTPUT" | grep -oP 'Loaded image: \K.+' | tail -1)
if [ -z "$LOADED_IMAGE" ]; then
    LOADED_IMAGE=$(echo "$LOADED_OUTPUT" | grep -oP 'Loaded image ID: \K.+' | tail -1)
fi

echo "Loaded: $LOADED_IMAGE"

# Tag to match what docker-compose.yml expects
EXPECTED_IMAGE=$(grep -E '^\s*image:' docker-compose.yml | head -1 | awk '{print $2}')
if [ -n "$EXPECTED_IMAGE" ] && [ "$LOADED_IMAGE" != "$EXPECTED_IMAGE" ]; then
    echo "Tagging $LOADED_IMAGE → $EXPECTED_IMAGE"
    docker tag "$LOADED_IMAGE" "$EXPECTED_IMAGE"
fi

# ---- 2. Start ----
echo "[2/3] Starting services..."
docker compose up -d

# ---- 3. Health check ----
echo "[3/3] Waiting for server to become healthy..."
MAX_WAIT=90
WAITED=0
HEALTHY=false

while [ $WAITED -lt $MAX_WAIT ]; do
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
    echo "Container logs:"
    docker compose logs --tail 50
    exit 1
fi

# ---- Nginx (optional) ----
if [ -n "$DOMAIN" ]; then
    echo ""
    bash "$SCRIPT_DIR/setup-nginx.sh" "$DOMAIN" "$PORT"
fi

echo ""
echo "=========================================="
echo " Deployment complete!"
echo "=========================================="
echo ""
echo "  Health:  curl http://localhost:$PORT/health"
echo "  Admin:   http://localhost:$PORT/admin/"
echo "  Logs:    docker compose logs -f"
if [ -n "$DOMAIN" ]; then
    echo "  URL:     http://$DOMAIN"
fi
echo ""
echo "  To stop: docker compose down"
