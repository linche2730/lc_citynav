# CityNav + FlightGPT 中文完整运行指南

本文档面向学校 Linux 服务器。目标是：代码上传后，只改 `configs/paths.server.env` 里的路径，就能切换数据、权重、输出和缓存目录。

## 0. 当前项目里有什么

- `third_party/citynav/`：CityNav 上游源码，固定到 `372ecbd1df58b46ffaad91c118c4838b88b87710`。
- `third_party/FlightGPT/`：FlightGPT 上游源码，固定到 `a1dd6760b7064a3b63e0ec4f75ae5921b3c95f92`。
- `patches/`：我们对第三方源码做的路径适配 patch。
- `configs/paths.server.env`：服务器路径唯一配置入口。
- `scripts/`：clone、软链接、检查、运行 eval 的统一入口。
- `runs/`：本项目内的轻量占位目录；服务器上真实 run 默认写到 `RUNS_ROOT`。

注意：数据、权重、缓存、运行输出都不要进 Git。

## 1. 上传到学校服务器

推荐只上传仓库代码，不上传大数据和权重。服务器能访问 GitHub 时，`third_party` 可以重新拉。

```bash
cd /path/to/your/uav_repo
cd projects/citynav_flightgpt_repro
```

如果服务器不能访问 GitHub，就在本机提前保留 `third_party/citynav` 和 `third_party/FlightGPT` 两个目录一起传上去；否则在服务器上运行 bootstrap 即可。

## 2. 配置路径

复制并编辑服务器配置：

```bash
cd /path/to/your/uav_repo/projects/citynav_flightgpt_repro
cp configs/paths.example.env configs/paths.server.env
vim configs/paths.server.env
```

最重要的是先改这一行：

```bash
DATA_BASE=${PROJECT_ROOT:-$(pwd)}/data
```

建议服务器目录结构如下：

```text
projects/citynav_flightgpt_repro/data/
  citynav/
    cityrefer/
    citynav/
    rgbd-new/
    gsam/
    subblocks/
  flightgpt_data/
    training_data/
  model_weight/
    Qwen2.5-VL-7B-Instruct/
    Flightgpt/
    Flightgpt_SFT/
  weights/
  checkpoints/
  outputs/
  R1PhotoData/
  hf_home/
  runs/
```

如果你想把 CityNav 和 FlightGPT 数据放在同一个大目录，也可以直接在 `paths.server.env` 里把 `CITYNAV_DATA_ROOT`、`FLIGHTGPT_DATA_ROOT` 指到同一个位置。

## 3. 拉源码并应用 patch

```bash
bash scripts/bootstrap_sources.sh
```

这个脚本会做三件事：

- clone CityNav 和 FlightGPT；
- checkout 到固定 commit；
- 应用 `patches/*.patch` 中的路径适配。

如果你已经手动上传了 `third_party`，也可以运行这个脚本；它会检查 patch 是否已经应用。

## 4. 建立软链接

```bash
bash scripts/prepare_paths.sh --env configs/paths.server.env
```

它会把第三方源码里的固定目录接到你在 `.env` 里配置的真实目录，例如：

- `third_party/FlightGPT/data -> FLIGHTGPT_DATA_ROOT`
- `third_party/FlightGPT/model_weight -> FLIGHTGPT_MODEL_ROOT`
- `third_party/FlightGPT/experiment -> FLIGHTGPT_OUTPUT_ROOT`
- `third_party/citynav/data -> CITYNAV_DATA_ROOT`
- `third_party/citynav/weights -> CITYNAV_WEIGHTS_ROOT`

如果它提示拒绝替换某个非空目录，先检查那个目录是不是已有旧数据。不要盲目删除原始数据。

## 5. 准备 Python 环境

FlightGPT 官方推荐 Python 3.11、PyTorch 2.6.0 + CUDA 12.4。H100 优先用 CUDA 12.x 路线。

```bash
conda create -n flightgpt python=3.11 -y
conda activate flightgpt

pip install torch==2.6.0+cu124 torchvision==0.21.0+cu124 torchaudio==2.6.0+cu124 \
  --index-url https://download.pytorch.org/whl/cu124
pip install -r third_party/FlightGPT/requirements.txt
pip install vllm

cd third_party/FlightGPT/open-r1-multimodal
pip install -e .
cd ../../..
```

CityNav MGP baseline 的官方环境更偏 Python 3.10 / CUDA 11.8。如果和 FlightGPT 环境冲突，建议单独建一个 `citynav` 环境跑 MGP baseline。

## 6. 准备数据和权重

先加载路径变量，后面命令会用到：

```bash
set -a
source configs/paths.server.env
set +a
mkdir -p "$DATA_BASE" "$HF_HOME"
```

### 6.1 FlightGPT / Qwen 权重

如果服务器能访问 Hugging Face，可用：

```bash
hf download Qwen/Qwen2.5-VL-7B-Instruct \
  --local-dir "$QWEN25_VL_ROOT"

hf download ADJHD/Flightgpt \
  --local-dir "$FLIGHTGPT_FINAL_ROOT"

hf download ADJHD/Flightgpt_SFT \
  --local-dir "$FLIGHTGPT_SFT_ROOT"
```

如果服务器不能访问 Hugging Face，就在能访问的机器上下载后，按同样目录拷到服务器。

### 6.2 FlightGPT 训练数据

```bash
hf download ADJHD/flightgpt_training_data \
  --repo-type dataset \
  --local-dir "$FLIGHTGPT_DATA_ROOT"
```

下载后检查是否有这些目录或文件：

```bash
ls "$FLIGHTGPT_DATA_ROOT"
ls "$FLIGHTGPT_TRAIN_DATA_ROOT"
```

如果 HF 数据包里包含 `citynav/`、`rgbd-new/`、`cityrefer/`，可以复制或软链到 `CITYNAV_DATA_ROOT` 对应目录。示例：

```bash
mkdir -p "$CITYNAV_DATA_ROOT"
rsync -a "$FLIGHTGPT_DATA_ROOT/citynav/" "$CITYNAV_ANNOTATION_DIR/"
rsync -a "$FLIGHTGPT_DATA_ROOT/rgbd-new/" "$CITYNAV_RGBD_DIR/"
rsync -a "$FLIGHTGPT_DATA_ROOT/cityrefer/" "$CITYREFER_DATA_DIR/"
```

### 6.3 CityNav 官方数据和权重

也可以用 CityNav 官方脚本下载 annotation、weights 和 checkpoint：

```bash
cd third_party/citynav
sh scripts/download_data.sh
sh scripts/download_weights.sh
cd ../..
```

这些脚本会写入 `third_party/citynav/data` 和 `third_party/citynav/weights`；如果第 4 步软链接已经建好，实际会落到 `.env` 指定的外部目录。

SensatUrban 点云和 rasterize 流程只在你要重建 `rgbd-new` / `rgbd` 时需要。快速复现 FlightGPT eval 时，优先使用已经处理好的 `rgbd-new`。

## 7. 检查路径是否齐全

```bash
bash scripts/check_paths.sh --env configs/paths.server.env
```

这个脚本不会修改数据。它会报告：

- CityNav annotation 是否存在；
- `rgbd-new/*.png` 和 `rgbd-new/*.tif` 是否存在；
- CityRefer metadata 是否存在；
- Qwen / FlightGPT / SFT 权重是否存在；
- training data 是否存在；
- MGP checkpoint 是否存在。

在所有必需项是 `[OK]` 之前，不要跑正式实验。

## 8. CityNav 数据 smoke test

先做一个轻量 JSON + 图像目录检查：

```bash
python scripts/smoke_citynav_dataset.py \
  --annotation-dir "$CITYNAV_ANNOTATION_DIR" \
  --rgbd-dir "$CITYNAV_RGBD_DIR" \
  --split easy
```

它只检查 split 文件、样本 key、png/tif 数量，不会调用模型。

## 9. FlightGPT dry-run smoke

dry-run 会加载 CityNav 数据并生成必要图像，但不调用 vLLM。

```bash
bash scripts/run_flightgpt_eval.sh \
  --env configs/paths.server.env \
  --limit 2 \
  --dry-run \
  --splits easy
```

输出位置：

```text
$RUNS_ROOT/vln/citynav_flightgpt_repro/<run_id>/
  command.txt
  eval.log
  manifest.json
```

只有 `manifest.json` 存在且 status 正常时，这个 smoke 才算通过。

## 10. 启动 vLLM

另开一个终端：

```bash
cd /path/to/your/uav_repo/projects/citynav_flightgpt_repro
conda activate flightgpt
set -a
source configs/paths.server.env
set +a

CUDA_VISIBLE_DEVICES=0,1,2,3 vllm serve "$QWEN25_VL_ROOT" \
  --dtype auto \
  --trust-remote-code \
  --served-model-name "$VLLM_MODEL_NAME" \
  --host 0.0.0.0 \
  --port 8888 \
  -tp 4 \
  --uvicorn-log-level info \
  --limit-mm-per-prompt image=2,video=0 \
  --max-model-len=32000
```

如果改了端口，要同步改 `configs/paths.server.env` 里的：

```bash
VLLM_API_BASE=http://127.0.0.1:8888/v1
```

## 11. FlightGPT 小规模真实推理

vLLM 启动后，先跑 2 条：

```bash
bash scripts/run_flightgpt_eval.sh \
  --env configs/paths.server.env \
  --limit 2 \
  --splits easy
```

再逐步扩大：

```bash
bash scripts/run_flightgpt_eval.sh \
  --env configs/paths.server.env \
  --limit 20 \
  --splits easy medium hard
```

最后才跑完整：

```bash
bash scripts/run_flightgpt_eval.sh \
  --env configs/paths.server.env \
  --splits easy medium hard
```

注意：任何 SR、SPL、NE、OSR 数字，只有在对应 run 目录里有 `manifest.json`、`command.txt`、`eval.log` 时，才允许进入总结或论文材料。

## 12. CityNav MGP baseline

确认 MGP checkpoint 路径：

```bash
echo "$CITYNAV_MGP_CHECKPOINT"
ls "$CITYNAV_MGP_CHECKPOINT"
```

运行：

```bash
bash scripts/run_citynav_mgp_eval.sh --env configs/paths.server.env
```

如果 checkpoint 不在默认路径，可以显式指定：

```bash
bash scripts/run_citynav_mgp_eval.sh \
  --env configs/paths.server.env \
  --checkpoint /path/to/mgp_mturk.pth
```

MGP baseline 的指标必须和 `baselines/local/citynav_mgp/json/metric_contract.json` 对齐后，才能作为对比基线。

## 13. SFT 配置渲染

SFT 使用 LLaMA-Factory。先渲染路径配置：

```bash
bash scripts/render_llamafactory_configs.sh --env configs/paths.server.env
```

然后进入 LLaMA-Factory：

```bash
cd third_party/FlightGPT/LLaMA-Factory
llamafactory-cli train examples/train_lora/qwen2vl_lora_sft.yaml
llamafactory-cli export examples/merge_lora/qwen2vl_lora_sft.yaml
cd ../../..
```

渲染脚本会把 `QWEN25_VL_ROOT`、SFT 输出目录、merge 输出目录写进 YAML，避免手动改绝对路径。

## 14. GRPO 训练入口

GRPO 脚本已经改成读取 `.env`：

```bash
cd third_party/FlightGPT
FLIGHTGPT_ENV_FILE=../../configs/paths.server.env \
  bash open-r1-multimodal/run_scripts/run_grpo_rec_lora.sh
cd ../..
```

默认使用：

- `CUDA_VISIBLE_DEVICES`：来自 `paths.server.env`；
- `NPROC_PER_NODE`：来自 `paths.server.env`；
- `QWEN25_VL_ROOT`：基础模型；
- `FLIGHTGPT_TRAIN_DATA_ROOT/citynav_train_data.json`：GRPO 数据；
- `FLIGHTGPT_TRAIN_DATA_ROOT/images`：训练图像；
- `FLIGHTGPT_OUTPUT_ROOT/FlightGPT`：输出目录。

如果你的训练 JSON 文件名和默认值不同，在 `paths.server.env` 里额外加：

```bash
CITYNAV_GRPO_DATA=/path/to/your_train.json
CITYNAV_GRPO_IMAGES=/path/to/images
```

## 15. 推荐执行顺序

```bash
# 1. 配置路径
vim configs/paths.server.env

# 2. 拉源码和 patch
bash scripts/bootstrap_sources.sh

# 3. 建软链接
bash scripts/prepare_paths.sh --env configs/paths.server.env

# 4. 准备/拷贝数据权重后检查
bash scripts/check_paths.sh --env configs/paths.server.env

# 5. 数据 smoke
set -a; source configs/paths.server.env; set +a
python scripts/smoke_citynav_dataset.py --annotation-dir "$CITYNAV_ANNOTATION_DIR" --rgbd-dir "$CITYNAV_RGBD_DIR" --split easy

# 6. FlightGPT dry-run
bash scripts/run_flightgpt_eval.sh --env configs/paths.server.env --limit 2 --dry-run --splits easy

# 7. 启 vLLM 后真实小样本
bash scripts/run_flightgpt_eval.sh --env configs/paths.server.env --limit 2 --splits easy

# 8. CityNav MGP baseline
bash scripts/run_citynav_mgp_eval.sh --env configs/paths.server.env
```

## 16. 常见问题

### `check_paths.sh` 报大量 missing

正常。它只检查，不下载。先确认 `DATA_BASE` 是否指向服务器真实数据盘，再补齐数据和权重。

### `prepare_paths.sh` 提示 refusing to replace non-empty path

说明第三方源码里已有同名非空目录。先检查目录内容。如果是旧缓存或旧软链接，可以手动迁走后重跑；如果是原始数据，不要删除。

### vLLM 能启动但 eval 连接不上

检查：

```bash
echo "$VLLM_API_BASE"
curl "$VLLM_API_BASE/models"
```

`VLLM_MODEL_NAME` 必须和 `vllm serve --served-model-name` 一致。

### Python import 报错

先确认在项目根目录运行脚本。包装脚本会自动设置 `PYTHONPATH`，不要直接在任意目录裸跑 `eval.py`。

### 中文路径乱码

Windows/WSL 混合环境可能显示乱码。学校 Linux 服务器建议把仓库放在纯英文路径下，例如 `/home/user/uav_repo/projects/citynav_flightgpt_repro`。

## 17. 结果可信规则

- 不要把终端里临时看到的数字写进论文。
- 每次正式 eval 必须保留 run 目录。
- 至少保留 `manifest.json`、`command.txt`、`eval.log`。
- 声称提升时必须说明对比对象、split、metric、seed/重复策略。
- 当前项目只完成路径可迁移接入；还没有 verified baseline metric。
