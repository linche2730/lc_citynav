#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
THIRD_PARTY="$PROJECT_ROOT/third_party"

CITYNAV_URL="https://github.com/water-cookie/citynav.git"
CITYNAV_COMMIT="372ecbd1df58b46ffaad91c118c4838b88b87710"
FLIGHTGPT_URL="https://github.com/Uavln/FlightGPT.git"
FLIGHTGPT_COMMIT="a1dd6760b7064a3b63e0ec4f75ae5921b3c95f92"

clone_checkout() {
    local url="$1"
    local dir="$2"
    local commit="$3"
    if [[ ! -d "$dir/.git" ]]; then
        git clone "$url" "$dir"
    fi
    git -C "$dir" fetch origin "$commit"
    git -C "$dir" checkout --detach "$commit"
}

apply_patch_if_needed() {
    local repo="$1"
    local patch_file="$2"
    if [[ ! -f "$patch_file" ]]; then
        return 0
    fi
    if git -C "$repo" apply --ignore-whitespace --reverse --check "$patch_file" >/dev/null 2>&1; then
        echo "Patch already applied: $patch_file"
    else
        git -C "$repo" apply --ignore-whitespace --whitespace=nowarn "$patch_file"
        echo "Applied patch: $patch_file"
    fi
}

mkdir -p "$THIRD_PARTY"
clone_checkout "$CITYNAV_URL" "$THIRD_PARTY/citynav" "$CITYNAV_COMMIT"
clone_checkout "$FLIGHTGPT_URL" "$THIRD_PARTY/FlightGPT" "$FLIGHTGPT_COMMIT"

if [[ "${APPLY_PATCHES:-1}" == "1" ]]; then
    apply_patch_if_needed "$THIRD_PARTY/citynav" "$PROJECT_ROOT/patches/citynav-path-adapter.patch"
    apply_patch_if_needed "$THIRD_PARTY/FlightGPT" "$PROJECT_ROOT/patches/flightgpt-path-adapter.patch"
fi

git -C "$THIRD_PARTY/citynav" rev-parse HEAD
git -C "$THIRD_PARTY/FlightGPT" rev-parse HEAD
