# HPCG Memory-Disambiguation Hazard 評価

RVV1.0 + Sniper 環境で HPCG ベクトルカーネルの memory disambiguation
パターンを計測した記録。HPCG をビルドし、SimPoint 代表区間で SIFT を
作り、Sniper の rob_timer 拡張で「load が memory dep のみで律速された
瞬間」と「Bloom Filter の偽陽性」を計測する。

ホスト python2 が消えているため、シミュレーションは Sniper 開発用
docker image (`msyksphinz/ubuntu:22.04-work-sniper-kimura-llvm16`) の
中で実行する。

---

## 1. リポジトリと配置

| パス | 役割 |
|------|------|
| `/home/kimura/work/sniper/vector_benches/` | benchmark 群とパイプライン (HPCG / Graph-V) |
| `vector_benches/hpcg-v-rvv10/` | HPCG submodule。branch `rvv10`、HEAD `2abfb38` (vsuxei) |
| `vector_benches/graph-wsg-out/hpcg_<N>/` | bbv / SimPoint / SIFT 出力 (size N=8/64/104) |
| `/home/kimura/work/sniper/prave_next_retry/` | 解析パイプライン (config / prepare / Sniper) |
| `prave_next_retry/sniper/` | Sniper source。branch `kimura/sift_qemu`、HEAD `72ad198` |
| `prave_next_retry/simulations/` | 各 (bench × config) ごとの sim dir |

主要な submodule commit:

```
hpcg-v-rvv10  2abfb38  ComputeProlongation_ref: RVV gather-modify-scatter via vsuxei32
hpcg-v-rvv10  a4f588f  Add SELL-p data structure + RVV-vectorize 5 HPCG kernels
sniper        72ad198  rob_timer: fix disambig hazard gain inflation for loads without reg deps
sniper        a82438b  rob_timer: detect memory-disambig hazard with per-(load_pc,store_pc) CSV
sniper        c3d2ecb  rob_timer: fix vec_store_queue typo causing wrap-around deadlock
prave_next    ee42d42  Add HAZARD-* configs for memory-disambig hazard analysis on graphv+HPCG
```

---

## 2. HPCG ビルド

ホストの clang/glibc は新しすぎてターゲットライブラリが揃わないので
docker image (ubuntu 22.04 + LLVM16 + riscv64 sysroot) の中でビルド。

```bash
docker run --rm \
  -v "$HOME:$HOME" -v "/tmp:/tmp" \
  --user $(id -u):$(id -g) \
  -w "/home/kimura/work/sniper/vector_benches/hpcg-v-rvv10" \
  msyksphinz/ubuntu:22.04-work-sniper-kimura-llvm16 \
  bash -c "make arch=RISCV_RVV10"
```

- toolchain: `/riscv/bin/clang++` (image 内)
- sysroot: `/usr/riscv64-linux-gnu/include` (image 内)
- target: `riscv64-unknown-linux-gnu`, `-march=rv64gcv -mabi=lp64d`
- 出力: `bin/xhpcg` (statically linked、qemu-riscv64 で実行)

主要ベクトル化箇所 (RVV1.0 intrinsics, USE_RISCV_VECTOR gated):

| ファイル | カーネル | 主命令 |
|----------|----------|--------|
| `src/SellpData.cpp` | SPMV (SELL-p) | `vluxei32`(gather) + `vfmacc` + `vse64` |
| `src/ComputeSPMV.cpp` | SPMV (CSR ref) | 同上 |
| `src/ComputeSYMGS.cpp` | SYMGS 内側ループ | `vluxei32` + `vfmacc` + `vfredusum` + scalar `fsd` |
| `src/ComputeProlongation_ref.cpp` | Prolongation | `vluxei32` + `vle64` + `vfadd` + **`vsuxei32`** (← 唯一の scatter) |
| `src/ComputeDotProduct.cpp` | DotProduct | `vle64` + `vfmacc` + `vfredusum` |
| `src/ComputeWAXPBY.cpp` | WAXPBY | `vle64` + `vfmacc` + `vse64` |

LMUL=1 統一が前提 (Sniper の static decoder が dynamic vlmul を追えない制約)。

---

## 3. SIFT 生成パイプライン

SimPoint で代表区間を選び、その始点に fast-forward した上で 1.5M 命令を
detailed 録音する。

```
make hpcg_bbv_<N>     # qemu + bbv plugin で BBV を取り、SimPoint で k=1 代表点
make hpcg_sift_<N>    # 代表点に ff、Sniper qemu-frontend plugin で 1.5M inst SIFT
```

実体は `vector_benches/Makefile` の `hpcg_sift_%` ターゲット。docker 内で:

```
qemu-riscv64 -plugin <sniper>/libqemu-frontend.so,...,fast_forward_target=<N>,detailed_target=1500000,output_file=<dir>/xhpcg_v1024 \
    /home/.../hpcg-v-rvv10/bin/xhpcg --nx=<N> --ny=<N> --nz=<N> --rt=1
```

出力: `graph-wsg-out/hpcg_<N>/xhpcg_v1024.0.sift` (約 3〜5 MB の trace)。

| size | fast_forward (inst) | 録音時間目安 |
|------|---------------------|--------------|
| 8    | 4.7×10⁸  | ~5 min |
| 64   | 3.2×10¹⁰ | ~5 min |
| 104  | 1.4×10¹¹ | ~20 min |

並列実行:
```bash
make -C vector_benches HPCG_SIZES="8 64 104" hpcg-sift-parallel
```

注意: SimPoint 座標は古い binary の BBV で決まる。binary を再構築 (例:
今回の vsuxei 追加) しても BBV を取り直さない限り、同じ「instruction
offset」で fast-forward するため、実際に踏むコードが微妙にずれることが
ある。size=64/104 で Prolongation を踏まなかったのはこの効果。

---

## 4. Sniper シミュレーション

### 4.1 ビルド (docker 内)

```bash
docker run --rm -v "$HOME:$HOME" --user $(id -u):$(id -g) \
  -w "/home/kimura/work/sniper/prave_next_retry/sniper" \
  msyksphinz/ubuntu:20.04-work-sniper-kimura-llvm16 \
  bash -c "cd common && make -j16 && cd ../standalone && make -j16"
```

ホストビルドはターゲット sysroot のずれで動かないので docker 強制。

### 4.2 sim dir の生成

`prave_next_retry/runeval_config.py` の `config_set` を編集して
`prepare_directories.py` を回すと sim dir + `rerun.sh` が生成される。

HAZARD-* 系の config のみ regenerate するには:

```bash
cd /home/kimura/work/sniper/prave_next_retry
CONFIG_NAME_RE='^HAZARD-' PREP_CELLS=1 PREP_POOL_SIZE=8 python3 prepare_directories.py
```

- `CONFIG_NAME_RE`: 正規表現で対象 config を絞る
- `PREP_CELLS=1`: Sniper rerun.sh のみ生成 (mcpat はスキップ)
- per-config の `'benchmarks'` フィールドで bench list 上書き
- per-config の `'skip_mcpat': True` で電力評価をスキップ

### 4.3 実行 (docker 内)

```bash
cd prave_next_retry
python3 list_stale_sims.py                 # stale_dirs.txt を更新
# docker で並列実行
docker run --rm -v "$HOME:$HOME" -v "/tmp:/tmp" \
  --user $(id -u):$(id -g) \
  -w "/home/kimura/work/sniper/prave_next_retry/simulations" \
  msyksphinz/ubuntu:20.04-work-sniper-kimura-llvm16 \
  bash -c "make sniper -j16"
```

各 dir に `sim.stats.sqlite3` (Sniper stats DB)、`mem_disambig_hazard.csv`
(新規 hazard 詳細)、`sniper.log.gz` (ログ) が落ちる。

---

## 5. Hazard 検出機構 (Sniper rob_timer 拡張)

`prave_next_retry/sniper` ブランチ `kimura/sift_qemu` に実装。

### 5.1 概念

Sniper は SIFT を読むので load の物理アドレスが dispatch 時に既知 →
本物の OoO core で生じる「memory disambiguation flush」をそのまま再現
できない。代わりに **「register dep が解決済みで、唯一 memory dep だけ
がまだ resolve していない瞬間に load を発行しようとした」** を検出し、
それを "もし投機実行を許せば flush 相当の動きが起きた load" とみなす。

### 5.2 実装ポイント

- `DynamicMicroOp::m_mem_dep_seqnrs`: 通常の dep list と分離して
  memory-dep の seqnr を保持
- `memory_dependencies.cc`: 旧 exact-match + Bloom Filter 3 経路すべてで
  `addMemoryDependency()` を併発
- `RobEntry::{regReadyMax, memReadyMax, lastMemDepStorePc, lastMemDepAddr}`:
  dep が resolve した時刻を register 側 / memory 側に分けて保持
- load 発行時に `memReadyMax > regReadyMax && regReadyMax > 0` ならハザード
  カウント (`mem-disambig-hazard-count`)
- 各 `(load_pc, store_pc)` ペアを map に集計、sim 終了時に CSV にダンプ

### 5.3 新規 stats (sim.stats.sqlite3)

```
rob_timer.mem-disambig-hazard-count           # 件数
rob_timer.mem-disambig-hazard-vec-count       # うち vector load
rob_timer.mem-disambig-hazard-cycles-gain     # SubsecondTime: gap の合計
                                              # (= 並列 hazard の per-load 合計、
                                              #   elapsed 超え得る)
memory_access.num_vldq_conflict_check         # bloom 検査回数 (= vec load 数)
memory_access.num_vldq_conflict               # bloom match 回数
memory_access.num_vldq_conflict_false_positive  # うち真の overlap がなかった件数
```

### 5.4 CSV (`mem_disambig_hazard.csv`)

```
load_pc,store_pc,count,cycles_gain_fs,is_vector,sample_addr
0x1cf54,0x1cef8,11777,1287843500000,1,0x4a1ab0
0x1d006,0x1cf9a,974,123474000000,1,0x4a6f88
...
```

count 降順。各行は「この load PC が、この store PC を memory dep として
最後まで待たされた」累計回数。

---

## 6. 評価コンフィグレーション

`runeval_config.py` 末尾の `HAZARD-*` ファミリ:

| 名前 | phyreg | vec policy | bloom | 用途 |
|------|--------|------------|-------|------|
| `HAZARD-BASE_v16`           | 136 | alloc_none | off (実 VLDQ) | 理想 baseline |
| `HAZARD-RFLOW-NOBLOOM_v16`  | 104 | alloc_flow | off (実 VLDQ fallback) | bloom-only A/B 用 |
| `HAZARD-RESERVEFLOW_v16`    | 104 | alloc_flow | on, length=7  | 標準 RFLOW |
| `HAZARD-RFLOW-LEN6_v16`     | 104 | alloc_flow | on, length=6  (64 bit)   | length sweep |
| `HAZARD-RFLOW-LEN8_v16`     | 104 | alloc_flow | on, length=8  (256 bit)  | 同 |
| `HAZARD-RFLOW-LEN9_v16`     | 104 | alloc_flow | on, length=9  (512 bit)  | 同 |
| `HAZARD-RFLOW-LEN10_v16`    | 104 | alloc_flow | on, length=10 (1024 bit) | 同 |
| `HAZARD-RFLOW-LEN11_v16`    | 104 | alloc_flow | on, length=11 (2048 bit) | 同 |

対象 bench (23 本):

- Graph-V official: `bfs_{road,twitter,urand,web,kron}` × {bfs,cc,pr,sssp}
- HPCG: `hpcg_8`, `hpcg_64`, `hpcg_104`

HPCG は SimPoint で代表区間切り出し済みなので `--roi` も `--roi-script` も
使わず、SIFT 先頭から最後まで `inst_mode_*=detailed` で全部回す。

---

## 7. 主な結果

### 7.1 ベンチマーク別 メモリアクセス + Bloom Filter 詳細統計

`HAZARD-RESERVEFLOW_v16` (bloom length=7、128 bit) 構成での RFLW 実行
結果。**HPCG は新 SIFT (vsuxei in Prolongation 入り)、Graph-V は old
binary** (Graph-V 側は新 SIFT を作っていない)。

列の意味:
- **inst**: ROI 区間の実行命令数
- **all_loads**: 全 load 数 (scalar + vector)
- **vec_loads**: bloom が check した回数 (= vector load 数)
- **match**: bloom が「overlap あり」と返した回数
- **FP**: そのうち実 overlap が無かった偽陽性数
- **FP/match**: bloom 発火のうち偽陽性の割合 (= bloom 自体の的中率の裏)
- **FP/load**: 全 load の何 % が bloom 偽陽性で待たされたか (workload に対する害の指標)
- **hazard**: rob_timer の mem-disambig-hazard-count (load が mem dep のみで律速された回数)

#### Graph-V official (20 bench)

| bench | inst | all_loads | vec_loads | match | FP | FP/match | FP/load | hazard |
|-------|------|-----------|-----------|-------|----|----------|---------|--------|
| **BFS** | | | | | | | | |
| bfs_road    |   481,969 |   118,318 |    18,246 |       0 |       0 |   — | 0.00% |    200 |
| bfs_twitter |   468,801 |   325,298 |   268,839 |   2,965 |   2,965 | **100.0%** |   0.91% |  2,675 |
| bfs_urand   |   476,210 |   252,267 |   186,166 |   2,457 |   2,457 | **100.0%** |   0.97% |  2,271 |
| bfs_web     |   478,089 |   117,567 |    92,051 |     307 |     307 | **100.0%** |   0.26% |     67 |
| bfs_kron    |   473,329 |   263,498 |   191,960 |   2,305 |   2,305 | **100.0%** |   0.87% |  2,064 |
| **CC** | | | | | | | | |
| cc_road     |   479,449 |   621,461 |   557,367 |       0 |       0 |   — | 0.00% |      0 |
| cc_twitter  |   490,876 |   580,596 |   473,761 |       0 |       0 |   — | 0.00% |      0 |
| cc_urand    |   474,237 |   701,726 |   662,217 |       0 |       0 |   — | 0.00% |      0 |
| cc_web      |   476,383 |   263,668 |   200,745 |     345 |     345 | **100.0%** |   0.13% |      0 |
| cc_kron     |   488,382 |   399,698 |   304,611 |       0 |       0 |   — | 0.00% |      0 |
| **PR** | | | | | | | | |
| pr_road     |   499,994 |   465,337 |   365,393 | 100,302 | 100,302 | **100.0%** | **21.55%** | 86,088 |
| pr_twitter  |   499,995 |   912,843 |   855,755 |  57,130 |  57,130 | **100.0%** |   6.26% | 16,436 |
| pr_urand    |   499,991 |   894,089 |   835,570 |  77,009 |  77,009 | **100.0%** |   8.61% |  4,678 |
| pr_web      |   499,995 |   942,590 |   888,304 |  13,211 |  13,211 | **100.0%** |   1.40% |  3,039 |
| pr_kron     |   499,995 |   907,996 |   849,349 |  73,393 |  73,393 | **100.0%** |   8.08% | 25,818 |
| **SSSP** | | | | | | | | |
| sssp_road   |   496,058 |   563,642 |   440,889 |       0 |       0 |   — | 0.00% |      0 |
| sssp_twitter|   499,990 |   670,177 |   582,358 |       0 |       0 |   — | 0.00% |      0 |
| sssp_urand  |   495,519 |   646,450 |   561,503 |       0 |       0 |   — | 0.00% |      0 |
| sssp_web    |   499,997 |   671,299 |   583,590 |       0 |       0 |   — | 0.00% |      0 |
| sssp_kron   |   499,995 |   659,171 |   572,271 |       0 |       0 |   — | 0.00% |      0 |

**Graph-V のまとめ**:
- bloom が一度でも当たった bench (BFS 4本 + CC 1本 + PR 全5本 = 10/20)、それ
  以外 (SSSP 全部、CC 4本、bfs_road) は bloom 発火ゼロ。
- **発火した bench は例外なく FP/match = 100%** — 1 件も真の overlap が無く、
  全てが Bloom Filter の偽陽性。Graph アルゴリズムは「vec store の直後に
  同じ番地へ vec load」というパターンを実質持たないため。
- PR が突出して FP 多発 (pr_road で全 load の **21.55%** が偽陽性)。これは
  PageRank が score 配列に push 更新を繰り返し、bloom が iteration 越しに
  「過去 store と当たる」を頻発させるため。
- ROI 区間で実 disambig hazard が立つのは BFS (4 bench) と PR (5 bench) のみ。
  CC/SSSP は hazard=0 (vec store パターンが薄い)。

#### HPCG (3 size, vsuxei 入り新 SIFT)

| bench | inst | all_loads | vec_loads | match | FP | FP/match | FP/load | hazard |
|-------|------|-----------|-----------|-------|----|----------|---------|--------|
| hpcg_8   | 1,499,999 | 1,159,475 | 965,962 | 47,023 | 34,617 | **73.6%** | 2.99% | 40,840 |
| hpcg_64  | 1,499,999 | 1,019,455 | 792,171 | 64,588 | 42,216 | **65.4%** | 4.14% | 60,285 |
| hpcg_104 | 1,499,999 | 1,024,785 | 797,527 | 63,752 | 41,244 | **64.7%** | 4.02% | 59,062 |

**HPCG のまとめ**:
- 真陽性 (= match − FP) が 12K〜22K あり、Graph-V とは異なる質感。これは
  SYMGS の Gauss-Seidel chain や Prolongation scatter ↔ SYMGS gather といった、
  HPCG カーネル本来の load-after-store 依存。
- それでも **FP/match が 65〜74%** = bloom 発火の 2/3 は偽陽性。サイズが
  大きいほど真陽性比率は下がる傾向 (hpcg_8 26.4% → hpcg_104 35.3% 真陽性)。
- hazard 数は match 数より小さいが同オーダー — bloom dep のうち、ROB scheduling 上で
  「reg dep より遅く解決された」ものだけが hazard として計上される。

#### Bloom 発火回数の絶対値

| メトリクス | Graph-V 合計 | HPCG 合計 |
|-----------|------------:|----------:|
| 全 vec load | 8,827,275 | 2,555,660 |
| bloom match | 329,424 | 175,363 |
| bloom FP    | 329,424 (**100%**) | 118,077 (67.3%) |
| 真陽性      | **0** | 57,286 |

Graph 全 20 bench で **真陽性が 1 件も発生していない** — bloom は graph 系
ベンチに対しては純粋な偽陽性発生器として動作している。HPCG は対照的に、
1/3 程度は本物の load-after-store 依存を検出できている。

### 7.2 Bloom Length スイープ (FP/load %)

`bloom_filter_length` ∈ {6, 7, 8, 9, 10, 11} = {64, 128, 256, 512, 1024,
2048} bit。偽陽性率 (FP/load) は理論通り 1 桁ずつ減衰:

#### Graph-V (発火する 10 bench のみ)

| bench | L6 | L7 | L8 | L9 | L10 | L11 |
|-------|----|----|----|----|-----|-----|
| bfs_twitter |  4.34% | 0.91% | 0.10% | 0.01% | 0.00% | 0.00% |
| bfs_urand   |  4.93% | 0.97% | 0.16% | 0.03% | 0.00% | 0.00% |
| bfs_web     |  1.63% | 0.26% | 0.07% | 0.00% | 0.00% | 0.00% |
| bfs_kron    |  4.51% | 0.87% | 0.13% | 0.02% | 0.00% | 0.00% |
| cc_web      |  0.77% | 0.13% | 0.01% | 0.00% | 0.00% | 0.00% |
| **pr_road**     | **39.76%** | **21.55%** | **5.32%** | **0.71%** | **0.10%** | **0.02%** |
| pr_twitter  | 20.13% | 6.26% | 1.09% | 0.15% | 0.02% | 0.00% |
| pr_urand    | 26.07% | 8.61% | 1.55% | 0.24% | 0.04% | 0.00% |
| pr_web      |  6.13% | 1.40% | 0.23% | 0.04% | 0.00% | 0.00% |
| pr_kron     | 25.26% | 8.08% | 1.46% | 0.22% | 0.03% | 0.00% |

(bfs_road, sssp_*, cc_road/twitter/urand/kron は全 length で 0%)

#### HPCG (新 SIFT、vsuxei in Prolongation)

| bench | L6 | L7 | L8 | L9 | L10 | L11 |
|-------|----|----|----|----|-----|-----|
| hpcg_8   | 5.00% | 2.99% | 2.69% | 2.62% | 2.62% | 2.62% |
| hpcg_64  | 6.31% | 4.14% | 3.80% | 3.76% | 3.76% | 3.76% |
| hpcg_104 | 6.27% | 4.02% | 3.65% | 3.60% | 3.60% | 3.59% |

#### 観察

- HPCG は **length≥9 で plateau に到達** (hpcg_8=2.62%, hpcg_64=3.76%,
  hpcg_104=3.60%) = この plateau 値 = 「真の load-after-store overlap 率」。
  bloom を大きくしても消えない真陽性。
- Graph は全 bench で **length=10 (1024 bit) までに FP < 0.1% に落ちる**。
  Graph workload に対しては bloom サイズを 8 倍にするだけで実害ゼロに。
- pr_road は length=11 (2048 bit) でも 0.02% 残るのが最も渋い workload。
  Page Rank の score 配列更新が iteration 越しに大量の重複ハッシュを撃つ。

### 7.3 IPC 影響

`HAZARD-BASE_v16` を基準に IPC delta を見る (HPCG = vsuxei 入り新 SIFT):

| bench | IPC_BASE | IPC_NOBL | IPC_RFLW(L7) | IPC_RFLW(L11) | bloom 単独 (RFLW/NOBL) | FP/load |
|-------|----------|----------|--------------|---------------|------------------------|---------|
| hpcg_8   | 1.113 | 1.103 | 1.103 | 1.114 | ±0% | 2.99% |
| hpcg_64  | 0.908 | 0.868 | 0.874 | 0.856 | +0.7% | 4.14% |
| hpcg_104 | 0.903 | 0.870 | 0.863 | 0.868 | −0.8% | 4.02% |
| Graph-V (全 20) | 0.001〜0.024 | 同 | 同 | 同 | ±0.01% | 〜21.6% |

- **Graph-V は memory-bound (D-TLB MPKI 300+) に潰されて、どんな bloom
  hazard を作っても DRAM stall に隠蔽されて IPC に出ない**。
  TLB が `D-TLB 32 entry + S-TLB 1024 entry × 4KB page = reach 4 MB` し
  か無いのに、roadU 等の graph working set は ~500 MB。
- HPCG は size=64/104 で BASE→NOBL の段差が −3〜4% (alloc_flow +
  vec_store_inorder 機構のコスト)。Bloom 単独の影響は ±1% 内に収まる。
- **bloom コストの本体は「bloom 機構そのもの (真陽性 dep)」**、FP の追加
  コストは小さい (length=11 まで広げても IPC は L7 とほぼ同じ)。

### 7.4 vsuxei が作る新規 hazard pair

`ComputeProlongation_ref.cpp` を vector intrinsics 化済み:

```cpp
vluxei32_v_f64m1(xfv, vidx_u, vl);   // sparse gather xfv[f2c[i..]]
vle64_v_f64m1(xcv + i, vl);          // sequential load xcv[i..]
vfadd_vv_f64m1(...);                 // 加算
__riscv_vsuxei32_v_f64m1(xfv, vidx_u, vxf, vl);  // sparse scatter
```

HPCG binary に唯一の `vsuxei32.v` (PC 0x1d724) が入る。RFLW length=7 の
`mem_disambig_hazard.csv` を見ると、size=8 では Prolongation の vsuxei を
ターゲットにした新規 hazard ペアが立っている:

| size | vsuxei (0x1d724) を store_pc に持つ hazard |
|------|--------------------------------------------|
| 8    | 16 件 (load_pc=0x1cf54 SYMGS vluxei × 8、0x1cede SYMGS scalar × 7、0x1cf3a × 1) |
| 64   | 0 件 (SimPoint 区間が Prolongation を踏まず) |
| 104  | 0 件 (同上) |

HPCG カーネル内で **「Prolongation が scatter で xfv に書き、後段の SYMGS
が同じ xfv 要素を gather/load で読む」** という gather-modify-scatter ↔
gather 依存が観測可能になった。

size=64/104 で同じパターンが出ないのは bbv (= SimPoint 座標) が古い
binary 由来のままで、新バイナリの Prolongation を踏まない instruction
offset で fast-forward 終端しているため。BBV を取り直せば踏める可能性
あり。

---

## 8. 発見と含意

1. **Bloom Filter は graph workload で純粋なオーバーヘッド** (100% FP)。
   ただし graph は memory-bound すぎて IPC に出ない。HW コスト削減の
   観点では「graph では bloom off」が論理的。

2. **HPCG の真依存 (SYMGS Gauss-Seidel chain + Prolongation scatter) は
   実機の VLDQ でも避けられない**。新 SIFT (vsuxei 入り) では FP plateau
   が hpcg_8=2.62%, hpcg_64=3.76%, hpcg_104=3.60% で頭打ち = この値が
   ハードウェア的に消せない真陽性率。bloom_length≥10 (1024 bit) で graph
   側の FP はほぼ 0、HPCG 側も plateau に到達。HW コスト +112 byte。

3. **Sniper の本質的限界**: trace に物理アドレスが入っているので「投機
   失敗 → flush」は再現できない。HAZARD カウンタは "oracle 視点" の上限
   評価。

4. **TLB が graph workload のボトルネック**。S-TLB 4 MB reach vs working
   set ~500 MB。huge page か TLB 拡張が無いと bloom の影響を測定可能領域
   に出せない。

---

## 9. 再現手順 (clean state から)

```bash
# 0. Sniper を docker 内でビルド
cd /home/kimura/work/sniper/prave_next_retry/sniper
docker run --rm -v "$HOME:$HOME" --user $(id -u):$(id -g) \
  -w "$(pwd)" msyksphinz/ubuntu:20.04-work-sniper-kimura-llvm16 \
  bash -c "cd common && make -j && cd ../standalone && make -j"

# 1. HPCG を docker 内でビルド (vsuxei あり版)
cd /home/kimura/work/sniper/vector_benches/hpcg-v-rvv10
docker run --rm -v "$HOME:$HOME" --user $(id -u):$(id -g) \
  -w "$(pwd)" msyksphinz/ubuntu:22.04-work-sniper-kimura-llvm16 \
  bash -c "make arch=RISCV_RVV10"

# 2. SIFT 生成 (各 size、~5min/size)
make -C /home/kimura/work/sniper/vector_benches HPCG_SIZES="8 64 104" hpcg-sift-parallel

# 3. sim dir 生成
cd /home/kimura/work/sniper/prave_next_retry
CONFIG_NAME_RE='^HAZARD-' PREP_CELLS=1 python3 prepare_directories.py

# 4. stale 検出
python3 list_stale_sims.py    # simulations/stale_dirs.txt を更新

# 5. Sniper 実行 (docker、~10min)
docker run --rm -v "$HOME:$HOME" -v "/tmp:/tmp" --user $(id -u):$(id -g) \
  -w "$(pwd)/simulations" msyksphinz/ubuntu:20.04-work-sniper-kimura-llvm16 \
  bash -c "make sniper -j16"

# 6. 解析: 各 dir の mem_disambig_hazard.csv + sim.stats.sqlite3
sqlite3 simulations/hpcg_8_hazard_reserveflow_v16/sim.stats.sqlite3 \
  "SELECT n.metricname, v.value FROM names n
   JOIN \"values\" v ON n.nameid=v.nameid
   WHERE v.prefixid=(SELECT MAX(prefixid) FROM prefixes)
     AND n.metricname LIKE '%hazard%';"
```

---

## 付録: 重要ファイル一覧

- `prave_next_retry/runeval_config.py` — HAZARD-* config 定義 (commit `ee42d42`)
- `prave_next_retry/prepare_directories.py` — `CONFIG_NAME_RE`, `'benchmarks'`, `'skip_mcpat'` 対応
- `prave_next_retry/list_stale_sims.py` — per-config bench 制限を尊重
- `prave_next_retry/sniper/.../rob_timer.{h,cc}` — hazard 検出ロジック
- `prave_next_retry/sniper/.../memory_dependencies.cc` — `addMemoryDependency` 呼び出し
- `prave_next_retry/sniper/.../dynamic_micro_op.h` — `m_mem_dep_seqnrs`
- `vector_benches/hpcg-v-rvv10/src/ComputeProlongation_ref.cpp` — vsuxei 版
- `vector_benches/Makefile` — `hpcg_sift_<N>`, `hpcg-sift-parallel` ターゲット
