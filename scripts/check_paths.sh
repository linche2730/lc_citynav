#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"
parse_env_arg "$@"
load_env "$ENV_FILE"

status=0

check_path() {
    local label="$1"
    local path="$2"
    local required="${3:-required}"
    if [[ -e "$path" ]]; then
        echo "[OK] $label: $path"
    else
        echo "[MISSING] $label: $path"
        if [[ "$required" == "required" ]]; then
            status=1
        fi
    fi
    return 0
}

check_glob() {
    local label="$1"
    local pattern="$2"
    local required="${3:-required}"
    if compgen -G "$pattern" >/dev/null; then
        echo "[OK] $label: $pattern"
    else
        echo "[MISSING] $label: $pattern"
        if [[ "$required" == "required" ]]; then
            status=1
        fi
    fi
    return 0
}

check_path "CityNav repo" "$CITYNAV_REPO/.git"
check_path "FlightGPT repo" "$FLIGHTGPT_REPO/.git"
check_path "CityRefer objects" "$CITYREFER_DATA_DIR/objects.json"
check_path "CityRefer processed descriptions" "$CITYREFER_DATA_DIR/processed_descriptions.json" optional
check_path "CityNav val unseen easy" "$CITYNAV_ANNOTATION_DIR/citynav_val_unseen_easy.json"
check_path "CityNav val unseen medium" "$CITYNAV_ANNOTATION_DIR/citynav_val_unseen_medium.json"
check_path "CityNav val unseen hard" "$CITYNAV_ANNOTATION_DIR/citynav_val_unseen_hard.json"
check_glob "CityNav RGB images" "$CITYNAV_RGBD_DIR/*.png"
check_glob "CityNav height rasters" "$CITYNAV_RGBD_DIR/*.tif"
check_path "CityNav GSAM cache" "$CITYNAV_GSAM_DIR" optional
check_path "CityNav MGP checkpoint" "${CITYNAV_MGP_CHECKPOINT:-}" optional

check_path "Qwen2.5-VL model" "$QWEN25_VL_ROOT"
check_path "FlightGPT final model" "$FLIGHTGPT_FINAL_ROOT" optional
check_path "FlightGPT SFT model" "$FLIGHTGPT_SFT_ROOT" optional
check_path "FlightGPT training json" "$FLIGHTGPT_TRAIN_DATA_ROOT/citynav_train_data.json" optional
check_glob "FlightGPT training images" "$FLIGHTGPT_TRAIN_DATA_ROOT/images/*" optional
check_path "HF_HOME" "$HF_HOME" optional

exit "$status"
