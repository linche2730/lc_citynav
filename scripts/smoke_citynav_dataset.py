#!/usr/bin/env python
import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Lightweight CityNav data smoke check.")
    parser.add_argument("--annotation-dir", required=True)
    parser.add_argument("--rgbd-dir", required=True)
    parser.add_argument("--split", default="easy")
    args = parser.parse_args()

    split_path = Path(args.annotation_dir) / f"citynav_val_unseen_{args.split}.json"
    rgbd_dir = Path(args.rgbd_dir)
    if not split_path.exists():
        raise FileNotFoundError(split_path)
    if not rgbd_dir.exists():
        raise FileNotFoundError(rgbd_dir)

    data = json.loads(split_path.read_text(encoding="utf-8"))
    if isinstance(data, list):
        count = len(data)
        sample = data[0] if data else {}
    elif isinstance(data, dict):
        first_list = next((v for v in data.values() if isinstance(v, list)), [])
        count = len(first_list) if first_list else len(data)
        sample = first_list[0] if first_list else data
    else:
        raise TypeError(f"Unsupported JSON root type: {type(data).__name__}")

    png_count = len(list(rgbd_dir.glob("*.png")))
    tif_count = len(list(rgbd_dir.glob("*.tif")))
    print(json.dumps({
        "split_file": str(split_path),
        "episode_count_estimate": count,
        "sample_keys": sorted(sample.keys()) if isinstance(sample, dict) else [],
        "rgb_png_count": png_count,
        "height_tif_count": tif_count,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

