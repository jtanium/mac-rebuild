#!/bin/bash

# Docker Desktop Plugin for Mac Rebuild
# Handles backup and restore of Docker Desktop settings, containers, images, and volumes

# Plugin metadata
docker_description() {
    echo "Manages Docker Desktop settings, containers, images, and volumes"
}

docker_priority() {
    echo "35"  # After Homebrew but before applications
}

docker_has_detection() {
    return 0
}

docker_detect() {
    [[ -d "/Applications/Docker.app" ]] || \
    (command -v brew &> /dev/null && brew list --cask docker &>/dev/null) || \
    command -v docker &>/dev/null
}

docker_backup() {
    log "Checking for Docker Desktop..."

    if ! docker_detect; then
        echo "Docker Desktop not found, skipping..."
        return 0
    fi

    if ask_yes_no "Found Docker Desktop. Do you want to backup Docker settings and data?" "y"; then
        echo "INCLUDE_DOCKER:true" >> "$USER_PREFS"

        local backup_dir="$BACKUP_DIR/docker"
        mkdir -p "$backup_dir"
        mkdir -p "$backup_dir/images"
        mkdir -p "$backup_dir/containers"
        mkdir -p "$backup_dir/volumes"

        # Backup Docker Desktop settings
        docker_backup_settings "$backup_dir"

        # Check if Docker daemon is running
        if docker info &>/dev/null; then
            # Backup running containers and images
            docker_backup_containers "$backup_dir"
            docker_backup_images "$backup_dir"
            docker_backup_volumes "$backup_dir"
            docker_backup_networks "$backup_dir"
            docker_backup_compose_files "$backup_dir"
        else
            warn "Docker daemon not running. Only settings will be backed up."
            warn "Start Docker Desktop and run backup again to include containers and images."
        fi

        echo "✅ Docker backup completed"
    else
        echo "EXCLUDE_DOCKER:true" >> "$USER_PREFS"
    fi
}

docker_backup_settings() {
    local backup_dir="$1"

    log "Backing up Docker Desktop settings..."

    # Docker Desktop preferences
    local docker_prefs="$HOME/Library/Group Containers/group.com.docker"
    if [[ -d "$docker_prefs" ]]; then
        if [[ -f "$docker_prefs/settings.json" ]]; then
            cp "$docker_prefs/settings.json" "$backup_dir/" 2>/dev/null || handle_error "Docker settings" "Could not copy settings.json"
        fi

        # Backup Docker daemon configuration
        if [[ -f "$docker_prefs/daemon.json" ]]; then
            cp "$docker_prefs/daemon.json" "$backup_dir/" 2>/dev/null || handle_error "Docker daemon config" "Could not copy daemon.json"
        fi
    fi

    # Docker config directory
    if [[ -d "$HOME/.docker" ]]; then
        cp -r "$HOME/.docker" "$backup_dir/docker-config" 2>/dev/null || handle_error "Docker config" "Could not copy .docker directory"
    fi

    echo "✅ Docker settings backed up"
}

docker_backup_containers() {
    local backup_dir="$1"

    log "Backing up Docker containers..."

    # List all containers (running and stopped)
    docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}" > "$backup_dir/containers/container_list.txt" 2>/dev/null || handle_error "Container list" "Could not list containers"

    # Ask user which containers to backup
    echo ""
    echo "Current containers:"
    cat "$backup_dir/containers/container_list.txt"
    echo ""

    if ask_yes_no "Do you want to backup specific containers? (This will export them as tar files)" "n"; then
        echo "Enter container names or IDs to backup (space-separated), or 'all' for all containers:"
        read -r container_input

        if [[ "$container_input" == "all" ]]; then
            # Backup all containers
            docker ps -aq | while read -r container_id; do
                if [[ -n "$container_id" ]]; then
                    local container_name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's/^.//')
                    docker export "$container_id" > "$backup_dir/containers/${container_name:-$container_id}.tar" 2>/dev/null || warn "Could not export container $container_id"
                fi
            done
        else
            # Backup specific containers
            for container in $container_input; do
                if docker ps -a --format "{{.Names}}" | grep -q "^$container$" || docker ps -a --format "{{.ID}}" | grep -q "^$container"; then
                    local container_name=$(docker inspect --format='{{.Name}}' "$container" 2>/dev/null | sed 's/^.//' || echo "$container")
                    docker export "$container" > "$backup_dir/containers/${container_name}.tar" 2>/dev/null || warn "Could not export container $container"
                fi
            done
        fi
    fi

    echo "✅ Container backup completed"
}

docker_backup_images() {
    local backup_dir="$1"

    log "Backing up Docker images..."

    # List all images
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" > "$backup_dir/images/image_list.txt" 2>/dev/null || handle_error "Image list" "Could not list images"

    # Ask user which images to backup
    echo ""
    echo "Current images:"
    cat "$backup_dir/images/image_list.txt"
    echo ""

    if ask_yes_no "Do you want to backup specific images? (This may take significant disk space)" "n"; then
        echo "Enter image names/tags to backup (space-separated), or 'all' for all images:"
        read -r image_input

        if [[ "$image_input" == "all" ]]; then
            # Backup all images
            docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>" | while read -r image; do
                if [[ -n "$image" && "$image" != "<none>:<none>" ]]; then
                    local safe_name=$(echo "$image" | tr '/:' '_')
                    docker save "$image" > "$backup_dir/images/${safe_name}.tar" 2>/dev/null || warn "Could not save image $image"
                fi
            done
        else
            # Backup specific images
            for image in $image_input; do
                local safe_name=$(echo "$image" | tr '/:' '_')
                docker save "$image" > "$backup_dir/images/${safe_name}.tar" 2>/dev/null || warn "Could not save image $image"
            done
        fi
    fi

    echo "✅ Image backup completed"
}

docker_backup_volumes() {
    local backup_dir="$1"

    log "Backing up Docker volumes..."

    # List all volumes
    docker volume ls --format "table {{.Name}}\t{{.Driver}}" > "$backup_dir/volumes/volume_list.txt" 2>/dev/null || handle_error "Volume list" "Could not list volumes"

    echo ""
    echo "Current volumes:"
    cat "$backup_dir/volumes/volume_list.txt"
    echo ""

    if ask_yes_no "Do you want to backup volume data? (Recommended for persistent data)" "y"; then
        # Create a backup container to access volumes
        docker volume ls --format "{{.Name}}" | while read -r volume; do
            if [[ -n "$volume" ]]; then
                log "Backing up volume: $volume"
                docker run --rm -v "$volume:/volume-data" -v "$backup_dir/volumes:/backup" alpine tar czf "/backup/${volume}.tar.gz" -C /volume-data . 2>/dev/null || warn "Could not backup volume $volume"
            fi
        done
    fi

    echo "✅ Volume backup completed"
}

docker_backup_networks() {
    local backup_dir="$1"

    log "Backing up Docker networks..."

    # List custom networks (excluding default bridge, host, none)
    docker network ls --filter "type=custom" --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}" > "$backup_dir/networks.txt" 2>/dev/null || handle_error "Network list" "Could not list networks"

    # Backup network configurations
    docker network ls --filter "type=custom" --format "{{.Name}}" | while read -r network; do
        if [[ -n "$network" ]]; then
            docker network inspect "$network" > "$backup_dir/network_${network}.json" 2>/dev/null || warn "Could not inspect network $network"
        fi
    done

    echo "✅ Network backup completed"
}

docker_backup_compose_files() {
    local backup_dir="$1"

    log "Searching for docker-compose files..."

    # Find docker-compose files in common locations
    find "$HOME" -name "docker-compose.yml" -o -name "docker-compose.yaml" -o -name "compose.yml" -o -name "compose.yaml" 2>/dev/null | head -20 > "$backup_dir/compose_files.txt"

    if [[ -s "$backup_dir/compose_files.txt" ]]; then
        echo ""
        echo "Found docker-compose files:"
        cat "$backup_dir/compose_files.txt"
        echo ""

        if ask_yes_no "Do you want to backup these docker-compose files?" "y"; then
            mkdir -p "$backup_dir/compose"
            local counter=1
            while read -r compose_file; do
                if [[ -f "$compose_file" ]]; then
                    cp "$compose_file" "$backup_dir/compose/compose_${counter}_$(basename "$compose_file")" 2>/dev/null || warn "Could not copy $compose_file"
                    echo "$(dirname "$compose_file")" >> "$backup_dir/compose/compose_${counter}_location.txt"
                    ((counter++))
                fi
            done < "$backup_dir/compose_files.txt"
        fi
    fi

    echo "✅ Compose file search completed"
}

docker_restore() {
    log "Restoring Docker Desktop..."

    local backup_dir="$BACKUP_DIR/docker"

    # Check if Docker backup exists
    if [[ ! -d "$backup_dir" ]]; then
        echo "No Docker backup found, skipping..."
        return 0
    fi

    # Check if user wants to restore Docker
    if grep -q "EXCLUDE_DOCKER:true" "$USER_PREFS" 2>/dev/null; then
        echo "Docker restore excluded by user preference, skipping..."
        return 0
    fi

    # Install Docker Desktop if not present
    if ! docker_detect; then
        if ask_yes_no "Docker Desktop not found. Install it now?" "y"; then
            if command -v brew &>/dev/null; then
                brew install --cask docker || handle_error "Docker installation" "Could not install Docker Desktop"
                echo "✅ Docker Desktop installed"
                echo "⚠️  Please start Docker Desktop manually and then re-run restore to restore data"
                return 0
            else
                warn "Homebrew not available. Please install Docker Desktop manually from https://docker.com/products/docker-desktop"
                return 1
            fi
        else
            echo "Skipping Docker restore without Docker Desktop"
            return 0
        fi
    fi

    # Restore settings
    docker_restore_settings "$backup_dir"

    # Check if Docker daemon is running before restoring data
    if docker info &>/dev/null; then
        docker_restore_images "$backup_dir"
        docker_restore_containers "$backup_dir"
        docker_restore_volumes "$backup_dir"
        docker_restore_networks "$backup_dir"
        docker_restore_compose_files "$backup_dir"
    else
        warn "Docker daemon not running. Only settings restored."
        warn "Start Docker Desktop and run restore again to restore containers and images."
    fi

    echo "✅ Docker restore completed"
}

docker_restore_settings() {
    local backup_dir="$1"

    log "Restoring Docker Desktop settings..."

    # Restore Docker Desktop preferences
    local docker_prefs="$HOME/Library/Group Containers/group.com.docker"
    mkdir -p "$docker_prefs"

    if [[ -f "$backup_dir/settings.json" ]]; then
        cp "$backup_dir/settings.json" "$docker_prefs/" 2>/dev/null || handle_error "Docker settings restore" "Could not restore settings.json"
    fi

    if [[ -f "$backup_dir/daemon.json" ]]; then
        cp "$backup_dir/daemon.json" "$docker_prefs/" 2>/dev/null || handle_error "Docker daemon config restore" "Could not restore daemon.json"
    fi

    # Restore Docker config
    if [[ -d "$backup_dir/docker-config" ]]; then
        cp -r "$backup_dir/docker-config" "$HOME/.docker" 2>/dev/null || handle_error "Docker config restore" "Could not restore .docker directory"
    fi

    echo "✅ Docker settings restored"
}

docker_restore_images() {
    local backup_dir="$1"

    if [[ -d "$backup_dir/images" ]] && [[ -n "$(ls -A "$backup_dir/images"/*.tar 2>/dev/null)" ]]; then
        log "Restoring Docker images..."

        if ask_yes_no "Found backed up Docker images. Restore them?" "y"; then
            for image_file in "$backup_dir/images"/*.tar; do
                if [[ -f "$image_file" ]]; then
                    log "Loading image: $(basename "$image_file")"
                    docker load < "$image_file" 2>/dev/null || warn "Could not load image from $image_file"
                fi
            done
        fi

        echo "✅ Docker images restored"
    fi
}

docker_restore_containers() {
    local backup_dir="$1"

    if [[ -d "$backup_dir/containers" ]] && [[ -n "$(ls -A "$backup_dir/containers"/*.tar 2>/dev/null)" ]]; then
        log "Found backed up containers..."

        echo "⚠️  Container backups are available but require manual restoration."
        echo "   Container files are located at: $backup_dir/containers/"
        echo "   Use 'docker import <file> <name>' to import containers as images"
        echo "   Then create new containers from these images as needed"

        if [[ -f "$backup_dir/containers/container_list.txt" ]]; then
            echo ""
            echo "Original container information:"
            cat "$backup_dir/containers/container_list.txt"
        fi
    fi
}

docker_restore_volumes() {
    local backup_dir="$1"

    if [[ -d "$backup_dir/volumes" ]] && [[ -n "$(ls -A "$backup_dir/volumes"/*.tar.gz 2>/dev/null)" ]]; then
        log "Restoring Docker volumes..."

        if ask_yes_no "Found backed up Docker volumes. Restore them?" "y"; then
            for volume_file in "$backup_dir/volumes"/*.tar.gz; do
                if [[ -f "$volume_file" ]]; then
                    local volume_name=$(basename "$volume_file" .tar.gz)
                    log "Restoring volume: $volume_name"

                    # Create the volume
                    docker volume create "$volume_name" 2>/dev/null || warn "Could not create volume $volume_name"

                    # Restore volume data
                    docker run --rm -v "$volume_name:/volume-data" -v "$backup_dir/volumes:/backup" alpine tar xzf "/backup/$(basename "$volume_file")" -C /volume-data 2>/dev/null || warn "Could not restore data for volume $volume_name"
                fi
            done
        fi

        echo "✅ Docker volumes restored"
    fi
}

docker_restore_networks() {
    local backup_dir="$1"

    if [[ -f "$backup_dir/networks.txt" ]]; then
        log "Found backed up networks..."

        echo "⚠️  Network configurations are available for reference:"
        echo "   Network list: $backup_dir/networks.txt"
        echo "   Network configs: $backup_dir/network_*.json"
        echo "   Networks need to be recreated manually based on these configurations"
    fi
}

docker_restore_compose_files() {
    local backup_dir="$1"

    if [[ -d "$backup_dir/compose" ]]; then
        log "Found backed up docker-compose files..."

        echo "⚠️  Docker-compose files have been backed up to: $backup_dir/compose/"
        echo "   Review and copy them to appropriate locations manually"
        echo "   Location information is stored in corresponding *_location.txt files"
    fi
}
