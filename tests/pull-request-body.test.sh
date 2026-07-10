#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/message-builders.sh"
source "$SCRIPT_DIR/lib/pull-request-body.sh"

assert_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    case "$haystack" in
        *"$needle"*) : ;;
        *) printf 'Assertion failed for %s\nMissing: %s\n' "$label" "$needle" >&2; exit 1 ;;
    esac
}

body="$(build_pull_request_body 2 $'\n\n## Updated packages\n- foo: 1.0.0 -> 1.0.1' pnpm $'## Applied changes\n- foo')"
assert_contains "$body" "Applied \`pnpm audit --fix override\` to resolve vulnerabilities" "pnpm changes"
assert_contains "$body" "Resolves 2 open Dependabot security alerts." "plural security line"
assert_contains "$body" "## Applied changes" "applied changes section"

printf 'OK\n'
