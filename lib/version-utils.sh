#!/bin/bash

version_is_greater() {
    local left_version=$1
    local right_version=$2

    local left_major left_minor left_patch
    local right_major right_minor right_patch

    IFS='.' read -r left_major left_minor left_patch <<< "$left_version"
    IFS='.' read -r right_major right_minor right_patch <<< "$right_version"

    [ -z "$left_major" ] && return 1
    [ -z "$right_major" ] && return 1
    [ -z "$left_minor" ] && return 1
    [ -z "$right_minor" ] && return 1
    [ -z "$left_patch" ] && return 1
    [ -z "$right_patch" ] && return 1

    if [ "$left_major" -gt "$right_major" ]; then
        return 0
    fi

    if [ "$left_major" -lt "$right_major" ]; then
        return 1
    fi

    if [ "$left_minor" -gt "$right_minor" ]; then
        return 0
    fi

    if [ "$left_minor" -lt "$right_minor" ]; then
        return 1
    fi

    [ "$left_patch" -gt "$right_patch" ]
}