#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/tests/coverage-helpers.sh"
source "$SCRIPT_DIR/tests/assert-helpers.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

sample_source="$tmp_dir/sample.sh"
sample_trace="$tmp_dir/trace.log"

cat > "$sample_source" <<'EOF'
#!/bin/bash
echo one

# comment
echo two
EOF

cat > "$sample_trace" <<EOF
+$sample_source:2: echo one
++${sample_source}:5: echo two
EOF

assert_equals "2" "$(count_executable_lines "$sample_source")" "executable line count"
assert_equals "2" "$(extract_covered_lines "$sample_trace" "$sample_source" | awk 'NF { count += 1 } END { print count + 0 }')" "covered line count"
assert_equals "100.00" "$(coverage_percent 2 2)" "coverage percentage"

printf 'OK\n'