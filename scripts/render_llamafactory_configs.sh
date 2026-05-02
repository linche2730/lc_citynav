#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"
parse_env_arg "$@"
load_env "$ENV_FILE"

export LLAMAFACTORY_SFT_OUTPUT_DIR="${LLAMAFACTORY_SFT_OUTPUT_DIR:-$FLIGHTGPT_OUTPUT_ROOT/llamafactory/saves/qwen2_vl-7b/lora/sft}"
export LLAMAFACTORY_SFT_ADAPTER_DIR="${LLAMAFACTORY_SFT_ADAPTER_DIR:-$LLAMAFACTORY_SFT_OUTPUT_DIR}"
export LLAMAFACTORY_MERGE_OUTPUT_DIR="${LLAMAFACTORY_MERGE_OUTPUT_DIR:-$FLIGHTGPT_OUTPUT_ROOT/llamafactory/output/qwen2_vl_lora_sft}"

python - "$PROJECT_ROOT" "$FLIGHTGPT_REPO" <<'PY'
import os
import sys
from pathlib import Path

project_root = Path(sys.argv[1])
flightgpt_repo = Path(sys.argv[2])
template_dir = project_root / "configs" / "llamafactory"
out_train = flightgpt_repo / "LLaMA-Factory" / "examples" / "train_lora" / "qwen2vl_lora_sft.yaml"
out_merge = flightgpt_repo / "LLaMA-Factory" / "examples" / "merge_lora" / "qwen2vl_lora_sft.yaml"

values = {
    "QWEN25_VL_ROOT": os.environ["QWEN25_VL_ROOT"],
    "LLAMAFACTORY_SFT_OUTPUT_DIR": os.environ["LLAMAFACTORY_SFT_OUTPUT_DIR"],
    "LLAMAFACTORY_SFT_ADAPTER_DIR": os.environ["LLAMAFACTORY_SFT_ADAPTER_DIR"],
    "LLAMAFACTORY_MERGE_OUTPUT_DIR": os.environ["LLAMAFACTORY_MERGE_OUTPUT_DIR"],
}

for src, dst in [
    (template_dir / "qwen2vl_lora_sft.yaml.template", out_train),
    (template_dir / "qwen2vl_lora_merge.yaml.template", out_merge),
]:
    text = src.read_text(encoding="utf-8")
    for key, value in values.items():
        text = text.replace("{{" + key + "}}", value)
    dst.write_text(text, encoding="utf-8")
    print(f"rendered {dst}")
PY

