#!/bin/bash
set -e

SERVICE_PREFIX="biochemistry"
COMPOSE_FILE="docker-compose.yml"

echo "============================================"
echo "  Biochemistry — Starting Services"
echo "============================================"
echo ""
echo "  Services:"
echo "    - PostgreSQL  (port ${POSTGRES_PORT:-5432})"
echo "    - Redis       (port ${REDIS_PORT:-6379})"
echo "    - Backend     (port ${BACKEND_PORT:-8000})"
echo "    - Frontend    (port ${FRONTEND_PORT:-5175})"
echo ""
echo "  Building and starting containers..."
echo ""

docker compose -f "$COMPOSE_FILE" up --build -d

echo ""
echo "============================================"
echo "  Services are running!"
echo ""
echo "  Frontend:  http://localhost:${FRONTEND_PORT:-5175}"
echo "  Backend:   http://localhost:${BACKEND_PORT:-8000}"
echo "  API Docs:  http://localhost:${BACKEND_PORT:-8000}/docs"
echo "============================================"
echo ""
echo "  Shutdown options:"
echo "    [k] Stop containers (keep images)"
echo "    [q] Stop containers + remove images"
echo "    [v] Stop containers + remove images + remove volumes (full cleanup)"
echo ""

read -rp "  Enter option when ready to stop: " choice

case "$choice" in
    k|K)
        echo ""
        echo "  Stopping containers..."
        docker compose -f "$COMPOSE_FILE" down
        echo "  Containers stopped. Images retained."
        ;;
    q|Q)
        echo ""
        echo "  Stopping containers and removing images..."
        docker compose -f "$COMPOSE_FILE" down --remove-orphans
        docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "$SERVICE_PREFIX" | awk '{print $2}' | xargs -r docker rmi 2>/dev/null || true
        echo "  Containers stopped. Images removed."
        ;;
    v|V)
        echo ""
        echo "  Stopping containers, removing images and volumes..."
        docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans
        docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "$SERVICE_PREFIX" | awk '{print $2}' | xargs -r docker rmi 2>/dev/null || true
        echo "  Full cleanup complete."
        ;;
    *)
        echo ""
        echo "  Invalid option. Stopping containers (keeping images)..."
        docker compose -f "$COMPOSE_FILE" down
        ;;
esac

echo ""
echo "  Done."
