#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CITYNAV_REPO_DEFAULT="$PROJECT_ROOT/third_party/citynav"
FLIGHTGPT_REPO_DEFAULT="$PROJECT_ROOT/third_party/FlightGPT"

load_env() {
    local env_file="${1:-$PROJECT_ROOT/configs/paths.local.env}"
    if [[ ! -f "$env_file" && "$env_file" != /* ]]; then
        env_file="$PROJECT_ROOT/$env_file"
    fi
    if [[ ! -f "$env_file" ]]; then
        echo "Missing env file: $env_file" >&2
        return 2
    fi

    export PROJECT_ROOT
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a

    export CITYNAV_REPO="${CITYNAV_REPO:-$CITYNAV_REPO_DEFAULT}"
    export FLIGHTGPT_REPO="${FLIGHTGPT_REPO:-$FLIGHTGPT_REPO_DEFAULT}"
    export CITYNAV_PROJECT_ROOT="${CITYNAV_PROJECT_ROOT:-$CITYNAV_REPO}"
    export FLIGHTGPT_PROJECT_ROOT="${FLIGHTGPT_PROJECT_ROOT:-$FLIGHTGPT_REPO}"
    export CITYREFER_DATA_DIR="${CITYREFER_DATA_DIR:-$CITYNAV_DATA_ROOT/cityrefer}"
    export CITYNAV_ANNOTATION_DIR="${CITYNAV_ANNOTATION_DIR:-$CITYNAV_DATA_ROOT/citynav}"
    export CITYNAV_RGBD_DIR="${CITYNAV_RGBD_DIR:-$CITYNAV_DATA_ROOT/rgbd-new}"
    export CITYNAV_GSAM_DIR="${CITYNAV_GSAM_DIR:-$CITYNAV_DATA_ROOT/gsam}"
    export CITYNAV_SUBBLOCKS_DIR="${CITYNAV_SUBBLOCKS_DIR:-$CITYNAV_DATA_ROOT/subblocks}"
    export CITYNAV_CHECKPOINT_ROOT="${CITYNAV_CHECKPOINT_ROOT:-$DATA_BASE/checkpoints}"
    export FLIGHTGPT_TRAIN_DATA_ROOT="${FLIGHTGPT_TRAIN_DATA_ROOT:-$FLIGHTGPT_DATA_ROOT/training_data}"
    export FLIGHTGPT_PHOTO_ROOT="${FLIGHTGPT_PHOTO_ROOT:-$FLIGHTGPT_OUTPUT_ROOT/R1PhotoData}"
    export RUNS_ROOT="${RUNS_ROOT:-$PROJECT_ROOT/runs}"
}

parse_env_arg() {
    ENV_FILE="$PROJECT_ROOT/configs/paths.local.env"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --env)
                ENV_FILE="$2"
                shift 2
                ;;
            *)
                echo "Unknown argument: $1" >&2
                return 2
                ;;
        esac
    done
    export ENV_FILE
}
