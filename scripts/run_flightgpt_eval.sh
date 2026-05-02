#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

ENV_FILE="$PROJECT_ROOT/configs/paths.local.env"
LIMIT="${FLIGHTGPT_EVAL_LIMIT:-0}"
DRY_RUN=0
SPLITS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            ENV_FILE="$2"
            shift 2
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --splits)
            shift
            while [[ $# -gt 0 && "$1" != --* ]]; do
                SPLITS+=("$1")
                shift
            done
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

load_env "$ENV_FILE"
RUN_ID="${RUN_ID:-flightgpt_eval_$(date +%Y%m%d_%H%M%S)}"
RUN_DIR="$RUNS_ROOT/vln/citynav_flightgpt_repro/$RUN_ID"
mkdir -p "$RUN_DIR"

export RUN_ID
export CITYNAV_PROJECT_ROOT="$CITYNAV_REPO"
export FLIGHTGPT_PROJECT_ROOT="$FLIGHTGPT_REPO"
export PYTHONPATH="$FLIGHTGPT_REPO:${PYTHONPATH:-}"
export HF_HOME

if [[ "${#SPLITS[@]}" -eq 0 ]]; then
    SPLITS=(easy medium hard)
fi

cmd=(
    python "$FLIGHTGPT_REPO/eval.py"
    --citynav-dir "$CITYNAV_ANNOTATION_DIR"
    --rgbd-dir "$CITYNAV_RGBD_DIR"
    --output-dir "$RUN_DIR"
    --photo-root "$FLIGHTGPT_PHOTO_ROOT"
    --api-base "$VLLM_API_BASE"
    --api-key "$VLLM_API_KEY"
    --api-version "$VLLM_API_VERSION"
    --model "$VLLM_MODEL_NAME"
    --limit "$LIMIT"
    --splits "${SPLITS[@]}"
)

if [[ "$DRY_RUN" == "1" ]]; then
    cmd+=(--dry-run)
fi

printf '%q ' "${cmd[@]}" > "$RUN_DIR/command.txt"
printf '\n' >> "$RUN_DIR/command.txt"
export RUN_COMMAND
RUN_COMMAND="$(cat "$RUN_DIR/command.txt")"
export REPRO_ENV_FILE="$ENV_FILE"
export CITYNAV_SOURCE_COMMIT
export FLIGHTGPT_SOURCE_COMMIT
CITYNAV_SOURCE_COMMIT="$(git -C "$CITYNAV_REPO" rev-parse HEAD)"
FLIGHTGPT_SOURCE_COMMIT="$(git -C "$FLIGHTGPT_REPO" rev-parse HEAD)"
"${cmd[@]}" 2>&1 | tee "$RUN_DIR/eval.log"
