#!/bin/bash
# Start ChromaDB via Docker Compose.
# Called at login by launchd — waits for Docker Desktop to be ready first.

COMPOSE_FILE="$HOME/dotfiles/docker/docker-compose.yml"

until docker info &>/dev/null 2>&1; do
  sleep 2
done

docker compose -f "$COMPOSE_FILE" up -d
