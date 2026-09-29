#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

run_check() {
    local label="$1"
    shift
    printf '\n==> %s\n' "$label"
    if "$@"; then
        return 0
    else
        local status=$?
        printf 'FAILED: %s (exit %s)\n' "$label" "$status" >&2
        exit "$status"
    fi
}

run_check "Format (StyLua)" stylua --check src tests
run_check "Lint (Selene)" selene src tests

if command -v rojo >/dev/null 2>&1 && command -v luau-lsp >/dev/null 2>&1; then
    run_check "Generate Rojo sourcemap" rojo sourcemap default.project.json -o sourcemap.json
    run_check "Analyze Luau types" luau-lsp analyze --sourcemap sourcemap.json src
else
    printf '\nSKIP: type analysis requires both rojo and luau-lsp on PATH.\n'
fi

run_check "Unit tests (Lune)" lune run tests/run
printf '\nAll available checks passed.\n'
