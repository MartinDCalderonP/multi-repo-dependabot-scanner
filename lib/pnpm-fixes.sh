#!/bin/bash

extract_pnpm_update_details() {
    local install_output=$1

    printf '%s\n' "$install_output" | awk '
        /^[[:space:]]*[+-] / {
            line = $0
            sub(/^[[:space:]]*/, "", line)
            sign = substr(line, 1, 1)
            line = substr(line, 3)
            split(line, parts, " ")
            package_name = parts[1]
            version = parts[2]

            if (sign == "-") {
                old_versions[package_name] = version
                next
            }

            if (sign == "+" && package_name in old_versions) {
                printf "%s\t%s\t%s\n", package_name, old_versions[package_name], version
            }
            next
        }
    '
}

get_pnpm_installed_version() {
    local package_name=$1

    local lockfile_version=""

    if [ -f "pnpm-lock.yaml" ]; then
        lockfile_version=$(get_pnpm_lockfile_version "$package_name")
    fi

    if [ -n "$lockfile_version" ]; then
        echo "$lockfile_version"
        return
    fi

    local version=$(pnpm why "$package_name" 2>&1 | awk -v pkg="$package_name" '
        index($0, pkg) {
            line = substr($0, index($0, pkg) + length(pkg))
            sub(/^[^0-9]*/, "", line)
            if (match(line, /^[0-9]+\.[0-9]+\.[0-9]+/)) {
                print substr(line, RSTART, RLENGTH)
                exit
            }
        }
    ')

    if [ -n "$version" ]; then
        echo "$version"
        return
    fi

    version=$(pnpm list "$package_name" --depth Infinity --json 2>/dev/null | jq -r --arg pkg "$package_name" '
        .. | objects
        | select(.name? == $pkg)
        | .version?
        | select(. != null and . != "")
    ' | head -1)

    echo "$version"
}

get_pnpm_lockfile_version() {
    local package_name=$1
    local escaped_package_name=$(printf '%s' "$package_name" | sed 's/[.[\*^$()+?{|]/\\&/g; s|/|\\/|g')

    grep -E "^[[:space:]]*/${escaped_package_name}@[0-9]+\.[0-9]+\.[0-9]+:" pnpm-lock.yaml 2>/dev/null \
        | head -1 \
        | sed -E "s|^[[:space:]]*/${escaped_package_name}@([0-9]+\.[0-9]+\.[0-9]+):$|\1|"
}

fix_pnpm_vulnerabilities() {
    local alerts_json=$1
    local packages=$(echo "$alerts_json" | jq -r 'map(select(.security_vulnerability.first_patched_version.identifier != null and (.is_blocked != true or .blocked_reason != "dependabot_timed_out"))) | .[].dependency.package.name' | tr '\n' ' ')

    [ -z "$packages" ] && return 0

    print_info "$(t running_pnpm_install)"
    pnpm install 2>/dev/null
    print_info "$(t running_pnpm_audit)"
    pnpm audit --fix override 2>/dev/null
    print_info "$(printf "$(t updating_packages)" "$packages")"
    pnpm update $packages 2>/dev/null
    print_info "$(t running_pnpm_install)"
    local install_output=$(pnpm install 2>/dev/null)
    PACKAGE_UPDATE_DETAILS=$(extract_pnpm_update_details "$install_output")
}