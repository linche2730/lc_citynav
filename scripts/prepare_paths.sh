#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"
parse_env_arg "$@"
load_env "$ENV_FILE"

replace_with_symlink() {
    local target="$1"
    local link_path="$2"
    mkdir -p "$(dirname "$link_path")"

    if [[ -L "$link_path" ]]; then
        rm "$link_path"
    elif [[ -e "$link_path" ]]; then
        if [[ -d "$link_path" && -z "$(find "$link_path" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
            rmdir "$link_path"
        else
            echo "Refusing to replace non-empty path: $link_path" >&2
            return 3
        fi
    fi
    ln -s "$target" "$link_path"
    echo "$link_path -> $target"
}

mkdir -p "$FLIGHTGPT_OUTPUT_ROOT" "$FLIGHTGPT_PHOTO_ROOT" "$HF_HOME" "$RUNS_ROOT"

replace_with_symlink "$FLIGHTGPT_DATA_ROOT" "$FLIGHTGPT_REPO/data"
replace_with_symlink "$FLIGHTGPT_MODEL_ROOT" "$FLIGHTGPT_REPO/model_weight"
replace_with_symlink "$FLIGHTGPT_OUTPUT_ROOT" "$FLIGHTGPT_REPO/experiment"
replace_with_symlink "$FLIGHTGPT_PHOTO_ROOT" "$FLIGHTGPT_REPO/R1PhotoData"
replace_with_symlink "$CITYNAV_WEIGHTS_ROOT" "$FLIGHTGPT_REPO/weights"

replace_with_symlink "$CITYNAV_DATA_ROOT" "$CITYNAV_REPO/data"
replace_with_symlink "$CITYNAV_WEIGHTS_ROOT" "$CITYNAV_REPO/weights"
replace_with_symlink "$CITYNAV_CHECKPOINT_ROOT" "$CITYNAV_REPO/checkpoints"

