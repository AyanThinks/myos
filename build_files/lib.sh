#!/usr/bin/bash
# Shared helpers, sourced by every build step.
set -euo pipefail
CTX="${CTX:-/ctx}"
set -a
# shellcheck disable=SC1091
source "$CTX/config/os.env"
set +a

# read_list FILE -> prints non-empty, non-comment lines
read_list() {
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' "$1" | awk 'NF'
}
log()  { echo "[myos] $*"; }
warn() { echo "[myos][WARN] $*" >&2; }
