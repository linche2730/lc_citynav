# CityNav + FlightGPT Reproduction Workspace

This project imports the CityNav and FlightGPT codebases and makes their data, weight, cache, and output paths portable for a school server. By default, all non-Git assets live under this project at `data/`.

中文完整运行指南见 [`RUN_GUIDE_ZH.md`](RUN_GUIDE_ZH.md)。
上传包与服务器下载清单见 [`UPLOAD_DOWNLOADS_ZH.md`](UPLOAD_DOWNLOADS_ZH.md)。

## What Is Tracked

- `configs/*.env`: path contracts for local and server environments.
- `scripts/*.sh`: clone, symlink, check, render, and run wrappers.
- `patches/*.patch`: local source modifications that can be reapplied after a fresh clone.
- `experiments/README.md`: baseline, metrics, seeds, and failure-mode contract.
- `baselines/local/*/json/metric_contract.json`: metric contracts only; no verified metrics yet.

The source snapshots in `third_party/`, large data, weights, and run outputs are intentionally ignored by Git.

## Server Setup

On the server, edit one file first:

```bash
cd projects/citynav_flightgpt_repro
cp configs/paths.example.env configs/paths.server.env
$EDITOR configs/paths.server.env
```

Then bootstrap and wire paths:

```bash
bash scripts/bootstrap_sources.sh
bash scripts/prepare_paths.sh --env configs/paths.server.env
bash scripts/check_paths.sh --env configs/paths.server.env
```

`check_paths.sh` is allowed to fail before data and weights are copied; its job is to show exactly what is missing.

## FlightGPT Eval Smoke

After CityNav annotations, `rgbd-new`, and CityRefer metadata are present:

```bash
bash scripts/run_flightgpt_eval.sh --env configs/paths.server.env --limit 2 --dry-run --splits easy
```

This checks data loading and image generation without calling vLLM. For real inference, start vLLM with `QWEN25_VL_ROOT`, set `VLLM_API_BASE`, and run without `--dry-run`.

## CityNav MGP Baseline

After the MGP checkpoint is present:

```bash
bash scripts/run_citynav_mgp_eval.sh --env configs/paths.server.env
```

No metric should be treated as verified until the run directory contains `manifest.json` or the eval output has been reconciled into a manifest.
