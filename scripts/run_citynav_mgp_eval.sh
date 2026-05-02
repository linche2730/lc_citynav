#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

ENV_FILE="$PROJECT_ROOT/configs/paths.local.env"
CHECKPOINT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            ENV_FILE="$2"
            shift 2
            ;;
        --checkpoint)
            CHECKPOINT="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

load_env "$ENV_FILE"
CHECKPOINT="${CHECKPOINT:-${CITYNAV_MGP_CHECKPOINT:-}}"
if [[ -z "$CHECKPOINT" || ! -f "$CHECKPOINT" ]]; then
    echo "Missing MGP checkpoint. Set CITYNAV_MGP_CHECKPOINT or pass --checkpoint." >&2
    exit 2
fi

RUN_ID="${RUN_ID:-citynav_mgp_eval_$(date +%Y%m%d_%H%M%S)}"
RUN_DIR="$RUNS_ROOT/vln/citynav_flightgpt_repro/$RUN_ID"
mkdir -p "$RUN_DIR"

export RUN_ID
export CITYNAV_PROJECT_ROOT="$CITYNAV_REPO"
export PYTHONPATH="$CITYNAV_REPO:${PYTHONPATH:-}"

cmd=(
    python "$CITYNAV_REPO/main_goal_predictor.py"
    --mode eval
    --model mgp
    --altitude 50
    --gsam_use_segmentation_mask
    --gsam_box_threshold 0.20
    --eval_batch_size 200
    --eval_max_timestep 20
    --checkpoint "$CHECKPOINT"
)

(
    cd "$RUN_DIR"
    printf '%q ' "${cmd[@]}" > command.txt
    printf '\n' >> command.txt
    "${cmd[@]}" 2>&1 | tee eval.log
    python - "$RUN_ID" "$ENV_FILE" "$CITYNAV_REPO" "$CHECKPOINT" "$RUN_DIR" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

run_id, env_file, citynav_repo, checkpoint, run_dir = sys.argv[1:]
command = Path("command.txt").read_text(encoding="utf-8").strip()
source_commit = subprocess.check_output(["git", "-C", citynav_repo, "rev-parse", "HEAD"], text=True).strip()
manifest = {
    "run_id": run_id,
    "status": "completed_unverified",
    "env_file": env_file,
    "command": command,
    "source_commits": {"citynav": source_commit},
    "checkpoint": checkpoint,
    "run_dir": run_dir,
    "metrics_status": "not_reconciled",
}
Path("manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
PY
)
