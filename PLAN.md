# CityNav + FlightGPT Path-Portability Setup Plan

## Route

Import two upstream codebases as local, untracked source workspaces and keep all local changes as patch files under `patches/`.

## Source Identity

- CityNav: `https://github.com/water-cookie/citynav.git`, commit `372ecbd1df58b46ffaad91c118c4838b88b87710`.
- FlightGPT: `https://github.com/Uavln/FlightGPT.git`, commit `a1dd6760b7064a3b63e0ec4f75ae5921b3c95f92`.

## Command Path

- `scripts/bootstrap_sources.sh`: clone/check out sources and apply patches.
- `scripts/prepare_paths.sh --env configs/paths.server.env`: create server-side symlinks.
- `scripts/check_paths.sh --env configs/paths.server.env`: report missing data, weight, and cache paths.
- `scripts/run_flightgpt_eval.sh --env configs/paths.server.env --limit 2 --dry-run`: smoke path for FlightGPT without calling the model server.
- `scripts/run_citynav_mgp_eval.sh --env configs/paths.server.env`: CityNav MGP baseline evaluation when checkpoint/data are present.

## Acceptance

This setup is accepted only as an infrastructure import. No baseline metric is accepted until a run directory has a manifest and verified metric files.

