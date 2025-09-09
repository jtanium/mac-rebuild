#!/bin/bash

# Mac Rebuild Plugin System
# Core plugin management functionality

# Plugin system configuration
PLUGIN_DIR="${SCRIPT_DIR}/plugins"
ENABLED_PLUGINS_FILE="${BACKUP_DIR}/enabled_plugins.txt"

# Plugin registry - using simple string-based approach for compatibility
PLUGINS_LIST=""

# Initialize plugin system
init_plugin_system() {
    log "Initializing plugin system..."

    # Create plugin directory if it doesn't exist
    mkdir -p "$PLUGIN_DIR"

    # Load all available plugins
    load_plugins

    echo "✅ Plugin system initialized"
}

# Load all plugins from plugin directory
load_plugins() {
    if [ ! -d "$PLUGIN_DIR" ]; then
        return
    fi

    for plugin_file in "$PLUGIN_DIR"/*.sh; do
        if [ -f "$plugin_file" ]; then
            plugin_name=$(basename "$plugin_file" .sh)
            load_plugin "$plugin_name"
        fi
    done
}

# Load a specific plugin
load_plugin() {
    local plugin_name="$1"
    local plugin_file="$PLUGIN_DIR/${plugin_name}.sh"

    if [ ! -f "$plugin_file" ]; then
        echo "⚠️  Plugin not found: $plugin_name"
        return 1
    fi

    # Source the plugin file
    source "$plugin_file"

    # Register the plugin (simple space-separated list)
    case " $PLUGINS_LIST " in
        *" $plugin_name "*) ;;  # Already in list
        *) PLUGINS_LIST="$PLUGINS_LIST $plugin_name" ;;
    esac

    # Call plugin init function if it exists
    if type "${plugin_name}_init" >/dev/null 2>&1; then
        "${plugin_name}_init"
    fi

    echo "📦 Loaded plugin: $plugin_name"
}

# Check if a plugin is enabled
is_plugin_enabled() {
    local plugin_name="$1"

    # If no enabled plugins file exists, all plugins are enabled by default
    if [ ! -f "$ENABLED_PLUGINS_FILE" ]; then
        return 0
    fi

    grep -q "^$plugin_name$" "$ENABLED_PLUGINS_FILE" 2>/dev/null
}

# Enable a plugin
enable_plugin() {
    local plugin_name="$1"

    if [ ! -f "$ENABLED_PLUGINS_FILE" ]; then
        touch "$ENABLED_PLUGINS_FILE"
    fi

    if ! grep -q "^$plugin_name$" "$ENABLED_PLUGINS_FILE" 2>/dev/null; then
        echo "$plugin_name" >> "$ENABLED_PLUGINS_FILE"
    fi
}

# Disable a plugin
disable_plugin() {
    local plugin_name="$1"

    if [ -f "$ENABLED_PLUGINS_FILE" ]; then
        grep -v "^$plugin_name$" "$ENABLED_PLUGINS_FILE" > "${ENABLED_PLUGINS_FILE}.tmp" 2>/dev/null || true
        mv "${ENABLED_PLUGINS_FILE}.tmp" "$ENABLED_PLUGINS_FILE"
    fi
}

# Get list of all plugins
get_all_plugins() {
    echo $PLUGINS_LIST
}

# Execute plugin hook for all enabled plugins
execute_plugin_hook() {
    local hook_name="$1"
    shift  # Remove hook_name from arguments, rest are passed to plugins

    for plugin_name in $(get_all_plugins); do
        if is_plugin_enabled "$plugin_name"; then
            local hook_function="${plugin_name}_${hook_name}"

            if type "$hook_function" >/dev/null 2>&1; then
                echo "🔧 Executing $hook_name for $plugin_name..."
                "$hook_function" "$@" || handle_error "$plugin_name $hook_name" "Plugin hook failed"
            fi
        fi
    done
}

# Get plugin priority (for execution order)
get_plugin_priority() {
    local plugin_name="$1"
    local priority_function="${plugin_name}_priority"

    if type "$priority_function" >/dev/null 2>&1; then
        "$priority_function"
    else
        echo "50"  # Default priority
    fi
}

# Execute plugins in priority order
execute_plugins_by_priority() {
    local hook_name="$1"
    shift

    # Create temporary file for sorting
    local temp_file="/tmp/mac_rebuild_plugins_$$"

    # Build priority list
    for plugin_name in $(get_all_plugins); do
        if is_plugin_enabled "$plugin_name"; then
            local priority=$(get_plugin_priority "$plugin_name")
            echo "$priority:$plugin_name" >> "$temp_file"
        fi
    done

    # Sort by priority and execute
    if [ -f "$temp_file" ]; then
        sort -t: -k1,1n "$temp_file" | while IFS=: read -r priority plugin_name; do
            if [ -n "$plugin_name" ]; then
                local hook_function="${plugin_name}_${hook_name}"

                if type "$hook_function" >/dev/null 2>&1; then
                    echo "🔧 Executing $hook_name for $plugin_name (priority $priority)..."
                    "$hook_function" "$@" || handle_error "$plugin_name $hook_name" "Plugin hook failed"
                fi
            fi
        done
        rm -f "$temp_file"
    fi
}

# Check if a plugin has specific capability
plugin_has_capability() {
    local plugin_name="$1"
    local capability="$2"

    local capability_function="${plugin_name}_has_${capability}"

    if type "$capability_function" >/dev/null 2>&1; then
        "$capability_function"
    else
        return 1
    fi
}

# Get plugin description
get_plugin_description() {
    local plugin_name="$1"
    local desc_function="${plugin_name}_description"

    if type "$desc_function" >/dev/null 2>&1; then
        "$desc_function"
    else
        echo "No description available"
    fi
}
