#!/bin/bash

has_uncommitted_changes() {
    return 1
}

pnpm() {
    if [ "$1" = "why" ]; then
        printf 'js-yaml@4.1.2\n'
        return 0
    fi

    if [ "$1" = "list" ]; then
        printf '[{"name":"root","dependencies":{"js-yaml":{"name":"js-yaml","version":"4.1.2"}}}]\n'
        return 0
    fi

    return 0
}

get_default_branch() {
    echo "main"
}

cleanup_pnpm_files() {
    return 0
}

git() {
    if [ "$1" = "pull" ]; then
        return 0
    fi

    return 0
}

gh() {
    if [ "$1" = "pr" ] && [ "$2" = "create" ]; then
        shift 2

        while [ "$#" -gt 0 ]; do
            if [ "$1" = "--body" ]; then
                printf '%s' "$2"
                break
            fi

            shift
        done

        return 0
    fi

    return 0
}

assert_equals() {
    local expected=$1
    local actual=$2
    local label=$3

    if [ "$expected" != "$actual" ]; then
        printf 'Assertion failed for %s\nExpected: %s\nActual:   %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}