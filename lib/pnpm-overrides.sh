#!/bin/bash

PATCHED_VERSIONS=""
REGISTRY_CACHE=""

get_registry_version() {
    local lookup=$1
    local cached=$(printf '%s\n' "$REGISTRY_CACHE" | grep -F "$lookup|" | cut -d'|' -f2 || true)
    if [ -n "$cached" ]; then
        echo "$cached"
        return
    fi

    local resolved=$(npm view "$lookup" version 2>/dev/null || true)
    if [ -n "$resolved" ]; then
        REGISTRY_CACHE="$REGISTRY_CACHE"$'\n'"$lookup|$resolved"
    fi
    echo "$resolved"
}

resolve_override_version() {
    local package_name=$1 current_value=$2
    local prefix=""
    if [[ "$current_value" =~ ^(\^|~) ]]; then
        prefix=${BASH_REMATCH[1]}
    fi

    local patched=$(printf '%s\n' "$PATCHED_VERSIONS" | grep -F "$package_name|" | cut -d'|' -f2 || true)
    if [ -n "$patched" ]; then
        echo "$prefix$patched"
        return
    fi

    if [[ "$current_value" == *:* || "$current_value" == */* ]]; then
        echo "$current_value"
        return
    fi

    if [ -n "$(get_registry_version "$package_name@$current_value")" ]; then
        echo "$current_value"
        return
    fi

    local latest=$(get_registry_version "$package_name")
    if [ -n "$latest" ]; then
        echo "$prefix$latest"
    else
        echo "$current_value"
    fi
}

fix_workspace_entry() {
    local line=$1 entry_type=$2
    local indent open_quote content close_quote value
    local override_pattern="^([[:space:]]+)(['\"]?)([^'\":]+)(['\"]?):[[:space:]]*(.*)\$"
    local exclude_pattern="^([[:space:]]+)-[[:space:]]*(['\"]?)([^'\"]+)(['\"]?)[[:space:]]*\$"

    if [ "$entry_type" = "overrides" ]; then
        [[ "$line" =~ $override_pattern ]] || { printf '%s' "$line"; return; }
        indent=${BASH_REMATCH[1]}
        open_quote=${BASH_REMATCH[2]}
        content=${BASH_REMATCH[3]}
        close_quote=${BASH_REMATCH[4]}
        value=${BASH_REMATCH[5]}
        [[ "$content" == \#* || -z "$value" ]] && { printf '%s' "$line"; return; }
        printf '%s%s%s%s: %s' "$indent" "$open_quote" "$content" "$close_quote" "$(resolve_override_version "${content%@*}" "$value")"
        return
    fi

    [[ "$line" =~ $exclude_pattern ]] || { printf '%s' "$line"; return; }
    indent=${BASH_REMATCH[1]}
    open_quote=${BASH_REMATCH[2]}
    content=${BASH_REMATCH[3]}
    close_quote=${BASH_REMATCH[4]}
    [[ "$content" == \#* || "$content" == *" || "* ]] && { printf '%s' "$line"; return; }
    printf '%s- %s%s@%s%s' "$indent" "$open_quote" "${content%@*}" "$(resolve_override_version "${content%@*}" "${content##*@}")" "$close_quote"
}

fix_pnpm_overrides() {
    local details=$1 yaml="pnpm-workspace.yaml"
    [ ! -f "$yaml" ] && return
    PATCHED_VERSIONS=""
    while IFS=$'\t' read -r package_name _ patched; do
        [ -n "$package_name" ] && [ -n "$patched" ] && PATCHED_VERSIONS="$PATCHED_VERSIONS"$'\n'"$package_name|$patched"
    done <<< "$details"

    local section=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^([[:space:]]*)(overrides|minimumReleaseAgeExclude):[[:space:]]*$ ]]; then
            section="${BASH_REMATCH[2]}"
        elif [[ "$line" == [^[:space:]]* ]] && [[ "$line" != \#* ]]; then
            section=""
        elif [ -n "$section" ]; then
            printf '%s\n' "$(fix_workspace_entry "$line" "$section")"
            continue
        fi
        printf '%s\n' "$line"
    done < "$yaml" > "${yaml}.tmp"
    mv "${yaml}.tmp" "$yaml"
}
