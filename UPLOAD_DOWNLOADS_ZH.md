# 上传包与服务器下载清单（相对路径版）

本项目现在默认采用“代码和数据放一起”的布局。服务器上解压后，所有数据、权重、输出、缓存默认都放在项目目录下的 `data/` 中。

## 1. 上传什么

上传这个压缩包即可：

```text
citynav_flightgpt_repro_relative_upload_20260502.tar.gz
```

解压后会得到：

```text
projects/citynav_flightgpt_repro/
```

上传包包含：

- 项目文档、脚本、配置；
- `patches/` 路径适配补丁；
- `third_party/citynav/` 源码快照；
- `third_party/FlightGPT/` 源码快照；
- baseline metric contract 和 provenance 文件。

上传包不包含：

- `.git/`
- `data/`
- `weights/`
- `model_weight/`
- `experiment/`
- `R1PhotoData/`
- 真实 `runs/`
- `__pycache__/`
- `*.pyc`

## 2. 默认相对目录结构

服务器上进入项目目录：

```bash
cd /path/to/uav_repo/projects/citynav_flightgpt_repro
```

默认配置文件是：

```bash
configs/paths.server.env
```

默认根目录：

```bash
DATA_BASE=${PROJECT_ROOT:-$(pwd)}/data
```

也就是数据默认放在：

```text
projects/citynav_flightgpt_repro/data/
```

建议最终目录结构：

```text
projects/citynav_flightgpt_repro/
  data/
    citynav/
      cityrefer/
        objects.json
        processed_descriptions.json
      citynav/
        citynav_train_seen.json
        citynav_val_seen.json
        citynav_val_unseen_easy.json
        citynav_val_unseen_medium.json
        citynav_val_unseen_hard.json
      rgbd-new/
        *.png
        *.tif
      gsam/
      subblocks/
    flightgpt_data/
      training_data/
        citynav_train_data.json
        images/
    model_weight/
      Qwen2.5-VL-7B-Instruct/
      Flightgpt/
      Flightgpt_SFT/
    weights/
      groundingdino/
      mobile_sam/
      som/
      vlnce/
    checkpoints/
      goal_predictor/
        mgp_mturk.pth
    outputs/
    R1PhotoData/
    hf_home/
    runs/
```

如果你以后想改成绝对路径，只改 `configs/paths.server.env` 里的：

```bash
DATA_BASE=/your/mounted/data/path
```

## 3. 解压后先做什么

```bash
cd /path/to/uav_repo
tar -xzf citynav_flightgpt_repro_relative_upload_20260502.tar.gz
cd projects/citynav_flightgpt_repro
```

如果包里已经带了 `third_party/`，通常不用重新 clone。仍建议跑一次：

```bash
bash scripts/bootstrap_sources.sh
```

然后建立相对路径软链接：

```bash
bash scripts/prepare_paths.sh --env configs/paths.server.env
```

它会把第三方源码中的固定目录链接到项目内 `data/`：

```text
third_party/FlightGPT/data         -> ./data/flightgpt_data
third_party/FlightGPT/model_weight -> ./data/model_weight
third_party/FlightGPT/experiment   -> ./data/outputs
third_party/FlightGPT/R1PhotoData  -> ./data/R1PhotoData
third_party/citynav/data           -> ./data/citynav
third_party/citynav/weights        -> ./data/weights
third_party/citynav/checkpoints    -> ./data/checkpoints
```

## 4. 必须下载/准备的内容

### A. FlightGPT 数据

来源：[ADJHD/flightgpt_training_data](https://huggingface.co/datasets/ADJHD/flightgpt_training_data)

下载到：

```text
$FLIGHTGPT_DATA_ROOT
```

默认实际位置：

```text
projects/citynav_flightgpt_repro/data/flightgpt_data/
```

命令：

```bash
set -a
source configs/paths.server.env
set +a

hf download ADJHD/flightgpt_training_data \
  --repo-type dataset \
  --local-dir "$FLIGHTGPT_DATA_ROOT"
```

下载后需要能找到：

```text
$FLIGHTGPT_TRAIN_DATA_ROOT/citynav_train_data.json
$FLIGHTGPT_TRAIN_DATA_ROOT/images/
```

如果数据包中有 `citynav/`、`cityrefer/`、`rgbd-new/`，请复制或软链到：

```text
$CITYNAV_ANNOTATION_DIR
$CITYREFER_DATA_DIR
$CITYNAV_RGBD_DIR
```

默认实际位置：

```text
data/citynav/citynav/
data/citynav/cityrefer/
data/citynav/rgbd-new/
```

### B. CityNav annotation / CityRefer / rgbd-new

来源可以是 FlightGPT 数据包，也可以是 [CityNav GitHub](https://github.com/water-cookie/citynav) 官方脚本。

如果用官方脚本：

```bash
bash scripts/prepare_paths.sh --env configs/paths.server.env

cd third_party/citynav
sh scripts/download_data.sh
cd ../..
```

最终必须放到：

```text
$CITYREFER_DATA_DIR/objects.json
$CITYREFER_DATA_DIR/processed_descriptions.json
$CITYNAV_ANNOTATION_DIR/citynav_val_unseen_easy.json
$CITYNAV_ANNOTATION_DIR/citynav_val_unseen_medium.json
$CITYNAV_ANNOTATION_DIR/citynav_val_unseen_hard.json
$CITYNAV_RGBD_DIR/*.png
$CITYNAV_RGBD_DIR/*.tif
```

默认实际位置：

```text
data/citynav/cityrefer/
data/citynav/citynav/
data/citynav/rgbd-new/
```

### C. Qwen2.5-VL 基座模型

来源：[Qwen/Qwen2.5-VL-7B-Instruct](https://huggingface.co/Qwen/Qwen2.5-VL-7B-Instruct)

下载到：

```text
$QWEN25_VL_ROOT
```

默认实际位置：

```text
data/model_weight/Qwen2.5-VL-7B-Instruct/
```

命令：

```bash
hf download Qwen/Qwen2.5-VL-7B-Instruct \
  --local-dir "$QWEN25_VL_ROOT"
```

### D. FlightGPT final 模型

来源：[ADJHD/Flightgpt](https://huggingface.co/ADJHD/Flightgpt)

下载到：

```text
$FLIGHTGPT_FINAL_ROOT
```

默认实际位置：

```text
data/model_weight/Flightgpt/
```

命令：

```bash
hf download ADJHD/Flightgpt \
  --local-dir "$FLIGHTGPT_FINAL_ROOT"
```

如果你只做 dry-run 或 Qwen 基座 smoke，可以先不下载这个。

### E. FlightGPT SFT 模型

来源：[ADJHD/Flightgpt_SFT](https://huggingface.co/ADJHD/Flightgpt_SFT)

下载到：

```text
$FLIGHTGPT_SFT_ROOT
```

默认实际位置：

```text
data/model_weight/Flightgpt_SFT/
```

命令：

```bash
hf download ADJHD/Flightgpt_SFT \
  --local-dir "$FLIGHTGPT_SFT_ROOT"
```

如果只跑最终模型 eval，可以先不下载；如果要复现 SFT 或 GRPO，建议下载。

### F. CityNav / MGP / GSAM 权重

来源：[CityNav GitHub](https://github.com/water-cookie/citynav)

下载命令：

```bash
bash scripts/prepare_paths.sh --env configs/paths.server.env

cd third_party/citynav
sh scripts/download_weights.sh
cd ../..
```

默认会进入：

```text
data/weights/
data/checkpoints/
```

MGP baseline checkpoint 默认路径：

```text
$CITYNAV_MGP_CHECKPOINT
```

默认实际位置：

```text
data/checkpoints/goal_predictor/mgp_mturk.pth
```

如果 checkpoint 实际文件名不同，直接改 `configs/paths.server.env`：

```bash
CITYNAV_MGP_CHECKPOINT=${CITYNAV_CHECKPOINT_ROOT}/path/to/your_mgp_checkpoint.pth
```

### G. SensatUrban 点云（可选）

来源：[SensatUrban](https://github.com/QingyongHu/SensatUrban)

只有在你要从点云重新生成 `rgbd-new` / `rgbd` 时才需要。快速复现 FlightGPT eval 通常不需要。

建议放到：

```text
data/sensaturban/
```

然后按 CityNav 官方 rasterize 流程生成到：

```text
$CITYNAV_RGBD_DIR
```

## 5. 下载后检查

```bash
cd /path/to/uav_repo/projects/citynav_flightgpt_repro

bash scripts/prepare_paths.sh --env configs/paths.server.env
bash scripts/check_paths.sh --env configs/paths.server.env
```

如果还有 `[MISSING]`，按提示补齐对应目录或文件。

## 6. 最小运行组合

### 只验证路径和数据加载

需要：

- CityNav annotation；
- CityRefer metadata；
- `rgbd-new/*.png` 和 `rgbd-new/*.tif`。

运行：

```bash
bash scripts/run_flightgpt_eval.sh \
  --env configs/paths.server.env \
  --limit 2 \
  --dry-run \
  --splits easy
```

### 跑 FlightGPT / Qwen 推理

需要：

- CityNav annotation；
- CityRefer metadata；
- `rgbd-new`；
- `QWEN25_VL_ROOT`；
- 如复现 FlightGPT final，再准备 `FLIGHTGPT_FINAL_ROOT`。

### 跑 CityNav MGP baseline

需要：

- CityNav annotation；
- CityRefer metadata；
- `rgbd-new`；
- CityNav / GSAM weights；
- `CITYNAV_MGP_CHECKPOINT`。

运行：

```bash
bash scripts/run_citynav_mgp_eval.sh --env configs/paths.server.env
```

### 跑 SFT / GRPO 训练

需要：

- Qwen2.5-VL；
- FlightGPT training JSON；
- training images；
- 多卡 GPU 环境。

SFT：

```bash
bash scripts/render_llamafactory_configs.sh --env configs/paths.server.env
cd third_party/FlightGPT/LLaMA-Factory
llamafactory-cli train examples/train_lora/qwen2vl_lora_sft.yaml
```

GRPO：

```bash
cd third_party/FlightGPT
FLIGHTGPT_ENV_FILE=../../configs/paths.server.env \
  bash open-r1-multimodal/run_scripts/run_grpo_rec_lora.sh
```

## 7. 可信记录

正式运行必须保留：

```text
$RUNS_ROOT/vln/citynav_flightgpt_repro/<run_id>/command.txt
$RUNS_ROOT/vln/citynav_flightgpt_repro/<run_id>/eval.log
$RUNS_ROOT/vln/citynav_flightgpt_repro/<run_id>/manifest.json
```

没有 manifest 的数字不要写进论文或总结。
