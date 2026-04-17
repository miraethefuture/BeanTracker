#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DERIVED_DATA_ROOT="${BEANTRACKER_DERIVED_DATA:-${REPO_ROOT}/.derivedData/codex}"
SIMULATOR_NAME="${BEANTRACKER_SIMULATOR:-iPhone 16}"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: missing required command '$1'" >&2
        exit 1
    fi
}
