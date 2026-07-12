#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/message-builders.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"
source "$SCRIPT_DIR/lib/pull-request-body.sh"

body="$(build_pull_request_body 2 $'\n\n## Updated packages\n- foo: 1.0.0 -> 1.0.1' pnpm $'## Applied changes\n- foo')"
assert_contains "$body" "Applied \`pnpm audit --fix override\` to resolve vulnerabilities" "pnpm changes"
assert_contains "$body" "Resolves 2 open Dependabot security alerts." "plural security line"
assert_contains "$body" "## Applied changes" "applied changes section"

singular_body="$(build_pull_request_body 1 '' pnpm '')"
assert_contains "$singular_body" "Resolves 1 open Dependabot security alert." "singular security line"

yarn_body="$(build_pull_request_body 3 '' yarn '## Applied changes\n- bar')"
assert_contains "$yarn_body" "Added Yarn resolutions" "yarn changes"

npm_body="$(build_pull_request_body 2 '' npm '## Applied changes\n- baz')"
assert_contains "$npm_body" "npm audit fix" "npm changes"

empty_update_body="$(build_pull_request_body 2 '' pnpm '')"
case "$empty_update_body" in
    *"Applied changes"*) printf 'FAIL: empty update_list should not have applied changes section\n' >&2; exit 1 ;;
    *) : ;;
esac

printf 'OK\n'
