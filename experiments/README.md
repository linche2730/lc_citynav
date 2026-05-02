# Experiment Card: CityNav + FlightGPT Reproduction

## Baselines

- Primary dataset baseline: CityNav MGP with human-demonstration trajectories.
- Primary model line: FlightGPT on CityNav with Qwen2.5-VL-family weights.
- Baseline state: imported and patched for path portability, not yet verified locally.

## Metrics

- `NE`: navigation error in meters, lower is better.
- `SR`: success rate, higher is better.
- `OSR`: oracle success rate, higher is better.
- `SPL`: success weighted by path length, higher is better.

## Seed Strategy

- Reproduction smoke tests use deterministic data subsets via `--limit`.
- Full runs must record seed values in the run manifest before any paper-facing comparison.
- No improvement claim is allowed from a single unmanifested run.

## Failure Modes

- Missing CityRefer metadata or annotation split files.
- `rgbd-new` / raster path mismatch between CityNav and FlightGPT.
- vLLM endpoint mismatch or wrong served model name.
- Missing Qwen2.5-VL / FlightGPT / SFT weights.
- GSAM or GroundingDINO path mismatch.
- Eval output exists but cannot be traced to source commit, env file, and command.

## Acceptance Gate

A run is usable only when its directory records source commits, env file, command, dataset paths, split, metric keys, and final status. Chat summaries are not evidence.

