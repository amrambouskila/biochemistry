#!/usr/bin/env bash
set -e

# ============================================================
#              CONFIGURATION
# ============================================================
SERVICE_PREFIX="biochemistry"
COMPOSE_FILE="docker-compose.yml"
DEV_OVERLAY="docker-compose.dev.yml"
COMPOSE_ARGS=(-f "$COMPOSE_FILE" -f "$DEV_OVERLAY")

# ============================================================
#              HELPERS
# ============================================================

print_banner() {
    echo "============================================"
    echo "  Biochemistry — Starting Services"
    echo "============================================"
    echo ""
    echo "  Services:"
    echo "    - PostgreSQL  (port ${POSTGRES_PORT:-5522})"
    echo "    - Redis       (port ${REDIS_PORT:-6522})"
    echo "    - Backend     (port ${BACKEND_PORT:-8222})"
    echo "    - Frontend    (port ${FRONTEND_PORT:-5175})"
    echo ""
}

start_services() {
    echo "  Building and starting containers..."
    echo ""
    docker compose "${COMPOSE_ARGS[@]}" up --build -d
    echo ""
    echo "============================================"
    echo "  Services are running!"
    echo ""
    echo "  Frontend:  http://localhost:${FRONTEND_PORT:-5175}"
    echo "  Backend:   http://localhost:${BACKEND_PORT:-8222}"
    echo "  API Docs:  http://localhost:${BACKEND_PORT:-8222}/docs"
    echo "============================================"
}

show_menu() {
    echo ""
    echo "  Menu:"
    echo "    [r] Restart (rebuild and relaunch)"
    echo "    [k] Stop containers (keep images)"
    echo "    [q] Stop containers + remove project images"
    echo "    [v] Stop containers + remove images + remove volumes (full cleanup)"
    echo ""
}

remove_project_images() {
    docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' \
        | grep "$SERVICE_PREFIX" \
        | awk '{print $2}' \
        | xargs -r docker rmi 2>/dev/null || true
}

# ============================================================
#              START
# ============================================================

print_banner
start_services
show_menu

# ============================================================
#              MAIN LOOP
# ============================================================

while true; do
    read -rp "  Enter option: " choice
    choice=$(printf '%s' "$choice" | tr '[:upper:]' '[:lower:]')

    case "$choice" in
        r)
            echo ""
            echo "  Restarting..."
            docker compose "${COMPOSE_ARGS[@]}" down
            echo ""
            start_services
            show_menu
            ;;
        k)
            echo ""
            echo "  Stopping containers..."
            docker compose "${COMPOSE_ARGS[@]}" down
            echo "  Containers stopped. Images retained."
            break
            ;;
        q)
            echo ""
            echo "  Stopping containers and removing project images..."
            docker compose "${COMPOSE_ARGS[@]}" down --remove-orphans
            remove_project_images
            echo "  Containers stopped. Images removed. Volumes retained."
            break
            ;;
        v)
            echo ""
            echo "  Stopping containers, removing images and volumes..."
            docker compose "${COMPOSE_ARGS[@]}" down --volumes --remove-orphans
            remove_project_images
            echo "  Full cleanup complete."
            break
            ;;
        *)
            echo "  Unrecognized option '${choice}'. Valid options: [r] [k] [q] [v]."
            show_menu
            ;;
    esac
done

echo ""
echo "  Done."
