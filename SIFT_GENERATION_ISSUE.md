<!--
GitHub Issue テンプレート: graph-v 新カーネル + HPCG の SIFT 生成トラッキング
そのまま新規 Issue 本文に貼り付けて使う。チェックボックスは進捗に応じて更新。
リポジトリ想定: kimura-sniper-docker-env (vector_benches)
-->

# [tracking] graph-v 新カーネル + HPCG の SIFT 生成

## 目的 (Goal)

`runeval_for_paper.py` の `graphv_official_benchmarks` に追加した新カーネル
(**bc / ccsv(cc_sv) / prspmv(pr_spmv) / tc**) × 5 グラフ (road/twitter/urand/web/kron) と
**HPCG** の SIFT を生成し、Sniper+MCPAT 評価へ投入できる状態にする。

最終成果物は各 bench dir の `rvv-test_v1024.0.sift` (+ `rvv-test_v1024.sift` symlink)。

## 現在の進捗 (Status 2026-05-28 23:33)

凡例: SIFT生成済み / SIFT生成中 / BBV取得中 / 要再生成 / 未着手

**全体**: official 20 (bfs/cc/pr/sssp×5, `graph-v-wsg/`) = 全て SIFT生成済み。HPCG 3 (hpcg_8/64/104) = 生成済み。新カーネル 20本 = **10 生成済み / 10 残り**。

新カーネル 20本 (`vector_benches/graph-wsg-out/<bench>U/`):

| prog | road | twitter | urand | web | kron |
|---|---|---|---|---|---|
| **bc** | SIFT生成済み | SIFT生成済み | SIFT生成済み | SIFT生成済み | SIFT生成済み |
| **ccsv** | SIFT生成済み | SIFT生成済み | SIFT生成済み | SIFT生成済み | SIFT生成済み |
| **tc** | SIFT生成済み | SIFT生成済み | SIFT生成済み | SIFT生成済み | SIFT生成済み |
| **prspmv** | SIFT生成済み | SIFT生成済み | SIFT生成済み | SIFT生成済み | SIFT生成済み |

**🎉 新カーネル 20/20 完了 (2026-05-30 05:49)。全体 43/43 (official 20 + HPCG 3 + 新 20)。**

完了サイズ (B): bc_road 1,180,065 / bc_twitter 1,485,666 / bc_urand 1,746,249 / bc_web 927,274 / bc_kron 1,580,817 / ccsv_road 2,788,285 / ccsv_twitter 9,889,696 / ccsv_urand 3,371,273 / ccsv_web 571,373 / ccsv_kron 3,307,133 / tc_road 645,382 / tc_twitter 1,358,581 / tc_urand 1,345,441 / tc_web 1,157,365 / tc_kron 1,107,606 / prspmv_road 2,309,724 / prspmv_twitter 1,242,376 / prspmv_urand 1,670,362 / prspmv_web 3,237,783 / prspmv_kron 4,461,201

**運用上の主な事象:**
- 2026-05-28 02:48: 外部要因で ccsv_road と prave_next2 が消失 → ccsv_road は full 再生成、プラグインは prave_next_retry/sniper に v4 fix を再ビルド。
- 2026-05-29 01:40 / 03:26: 7ジョブ並走で 134M グラフ4本同時 → ホスト OOM (エラー137)。prspmv_urand / ccsv_urand が SIGKILL。BBV+SimPoint 無傷だったため SIFT-only 再実行で復旧。
- 2026-05-29 16:00: tc_urand 長尾戦略実証。ROI start interval=2,348,487 (≈1.17T 命令)、post-ROI 10K interval (5B 命令) で force-kill → slice → SimPoint → SIFT。tc_kron も同戦略で 2026-05-30 05:49 完了。
- 教訓: **134M ノードの urand/kron は同時 3本まで** (4本で host OOM)。SIFT 内グラフ構築フェーズで各 ~150-175 GB を消費。

完了サイズ: bc_road 1180065 / bc_twitter 1485666 / bc_web 927274 / ccsv_twitter 9889696 / ccsv_web 571373 / ccsv_kron 3307133 / tc_road 645382 / tc_twitter 1358581 / tc_web 1157365 / prspmv_road 2309724 / prspmv_kron 4461201 (B) — **計 11 完了**

**実行中の runner** (setsid デタッチ, PRAVE_NEXT2_DIR=../prave_next_retry):
- `_cat23A_runner.sh`: ccsv_urand を SIFT生成中 (ff=1.25T)
- `_extra5_runner.sh`: bc_urand / bc_kron / prspmv_twitter / prspmv_web を BBV取得中 (このサーバで再実行, 全 -i 5)
- 未着手: tc_urand / tc_kron (pattern B 長尾) と ccsv_road 再生成

**prspmv_urand は OOM で失敗** (2026-05-29 01:40, エラー137 = 7ジョブ並走で 134M グラフ4本同時→ホスト OOM)。
BBV+SimPoint は無傷なので **SIFT のみ再実行**で足りる。メモリ衝突回避のため現行ジョブが減ってから再投入する。

**注**: ccsv_roadU は 2026-05-28 02:48 に外部要因で全消去 → full 再生成要。プラグインは prave_next2 消失のため prave_next_retry に v4 fix を再ビルド済 (PRAVE_NEXT2_DIR 上書き必須)。

## 背景 (Background)

- 既存 official 20本 (bfs/cc/pr/sssp × 5) と HPCG は SIFT 済。
- 新カーネルは `graph-wsg-out/<bench>U/` に SimPoint まで進んだものと、QEMU BBV が未完のものが混在。
- パイプライン: **QEMU BBV → SimPoint → (insnhist) → SIFT (Sniper qemu-frontend plugin)**。
  SIFT に insnhist は不要 (`qemu.log.roi` + `results.simpts` のみ必要)。

## 方針の決定事項 (Decisions)

- **bc / prspmv**: 反復数を `-i 5` に制限 (デフォルト50)。SimPoint は k=1 で定常区間1つを取るため、
  `-i` を減らしても代表区間としては `-i 50` の road/web と比較可能。
- **ccsv / tc**: 反復ループ無し (O(V+E) 単一パス / 内部収束)。`-i`/`-n` レバー無し → **full で直列完走待ち**。
- **並列度**: urand/kron は単独 ~100-150GB RSS。**1〜2本ずつ直列** (4本同時は過去に OOM)。
- メモリ運用: 65% WARN / 70% で最遅ジョブを `docker stop`。

## インフラ修正 (Makefile, 適用済み)

- [x] `graph_wsg_sift_%` ルールを `_sg`/`_wsg` 分割に修正 (WORKDIR/WORKLOAD 誤り、`ccsv→cc_sv`/`prspmv→pr_spmv` マッピング、`rvv-test_v1024.sift` symlink 生成を追加)
- [x] `graph-wsg-run-qemu-sift` に `LD_LIBRARY_PATH=$(SNIPER_ROOT)/xed_kit/lib` を追加 (libxed.so 解決)
- [x] `KERNEL_ARGS` を bbv/insnhist/sift の kernel 呼び出しに通す (bc/prspmv で `-i 5`)

## 状態マトリクス (Status)

凡例: ✅完了 / 🔄実行中 / ⬜未着手 / ⛔ BBV 未完 (要 BBV から)

### HPCG (SIFT 済)
- [x] hpcg_8 — SIFT ✅
- [x] hpcg_64 — SIFT ✅
- [x] hpcg_104 — SIFT ✅

### cat① BBV 完了済 → SIFT 生成のみ (bc/ccsv/tc × road/twitter/web)

> **✅ 復旧済み (2026-05-27)**: SIFT プラグインを持つ `../prave_next2` が消失していた (Makefile の
> `PRAVE_NEXT2_DIR ?= ../prave_next2` 前提が崩れ `SNIPER_ROOT` 空 → プラグインパス `/frontend/…` 化け →
> 全 SIFT が error 2 即死)。生存ツリーは全て旧 v2 プラグイン (SEGV 再発) だったため、**v4 fix を `prave_next_retry/sniper` に再適用して再ビルド**した:
> 1. `prave_next_retry/sniper/include/qemu-plugin.h` を docker イメージ (22.04) 内 `/riscv/include/qemu-plugin.h` (v4) で置換。v2 は `qemu-plugin.h.v2.bak` に退避。
> 2. `plugin.c` の `pluginVcpuTbTrans` に `#if QEMU_PLUGIN_VERSION >= 3` ガードを追加 — v4 の `qemu_plugin_insn_data(insn, buf, len)` (buffer コピー) 経路を実装 (v2 の ptr 戻しと両対応)。
> 3. 再ビルド: `make docker-cmd CMD='cd /home/kimura/work/sniper/prave_next_retry/sniper/frontend/qemu-frontend; rm -f *.o libqemu-frontend.so; make SIM_ROOT=/home/kimura/work/sniper/prave_next_retry/sniper'`
> 4. スモーク (bc+roadU, ff=50M): SEGV 無し・589KB SIFT (magic `SIFT` 一致) を確認。
>
> **SIFT 実行時は `PRAVE_NEXT2_DIR=../prave_next_retry` を make に渡すこと** (Makefile デフォルトは消えた prave_next2 のまま)。
> `_cat1_sift_runner.sh` は対応済み。road 3本 + ccsv_twitterU は無傷。残り 5本は復旧後 2026-05-27 に再実行 (🔄)。

| bench | BBV | SimPoint | SIFT |
|---|:--:|:--:|:--:|
| bc_roadU | ✅ | ✅ | ✅ |
| bc_twitterU | ✅ | ✅ | ⬜ |
| bc_webU | ✅ | ✅ | ⬜ |
| ccsv_roadU | ⛔消失 | ⛔消失 | ⛔消失 (2026-05-28 02:48 に外部要因で全消去, full 再生成要) |
| ccsv_twitterU | ✅ | ✅ | ✅ |
| ccsv_webU | ✅ | ✅ | ✅ |
| tc_roadU | ✅ | ✅ | ✅ |
| tc_twitterU | ✅ | ✅ | ✅ |
| tc_webU | ✅ | ✅ | ✅ |

- [x] bc_roadU / ccsv_roadU(※消失) / ccsv_twitterU / tc_roadU (SIFT 完了, prave_next2 健在時)
- [x] bc_twitterU / bc_webU / ccsv_webU / tc_twitterU / tc_webU (**SIFT 完了 2026-05-28**, v4 fix 復旧後)
  - `graph-wsg-out/_cat1_parallel_runner.sh` で**5本並列**生成 (setsid デタッチ, PRAVE_NEXT2_DIR=../prave_next_retry, output_file で個別コンテナ特定→early-kill)。
  - サイズ: bc_twitter 1485666B / ccsv_web 571373B / bc_web 927274B / tc_twitter 1358581B / tc_web 1157365B (全て magic `SIFT` 検証済, symlink 作成済)。
  - 途中 odaki さんの 256本バッチで load 576 まで上昇し ~半速に低下、負荷が引いてから完走。

### cat②③ BBV 未完 → BBV から再実行

| bench | 方式 | BBV | SimPoint | SIFT |
|---|---|:--:|:--:|:--:|
| bc_urandU | `-i 5` | ⛔ | ⬜ | ⬜ |
| bc_kronU | `-i 5` | ⛔ | ⬜ | ⬜ |
| prspmv_roadU | `-i 5` | ⛔ | ⬜ | ⬜ |
| prspmv_twitterU | `-i 5` | ⛔ | ⬜ | ⬜ |
| prspmv_urandU | `-i 5` | ⛔ | ⬜ | ⬜ |
| prspmv_webU | `-i 5` | ⛔ | ⬜ | ⬜ |
| prspmv_kronU | `-i 5` | ⛔ | ⬜ | ⬜ |
| ccsv_urandU | full | ⛔ | ⬜ | ⬜ |
| ccsv_kronU | full | ⛔ | ⬜ | ⬜ |
| tc_urandU | full | ⛔ | ⬜ | ⬜ |
| tc_kronU | full | ⛔ | ⬜ | ⬜ |

- [ ] bc urand/kron (BBV→SIFT, `-i 5`)
- [ ] prspmv road/twitter/urand/web/kron (BBV→SIFT, `-i 5`)
- [ ] ccsv urand/kron (BBV→SIFT, full)
- [ ] tc urand/kron (BBV→SIFT, full)

## 実行コマンド (Commands)

作業 dir: `vector_benches/` (Docker 内で実行される Makefile ターゲット)

```bash
# --- cat① SIFT のみ (BBV/SimPoint 済) ---
#   bc/ccsv/tc は -i 不問 (既存 BBV が -i 50 で取れているため SIFT も既存 ROI を使う)
make graph_wsg_sift_<prog>_<graph>U_sg
#   例: make graph_wsg_sift_bc_twitterU_sg

# --- cat②③ BBV から (bc/prspmv は -i 5、ccsv/tc は full) ---
#   BBV → SimPoint → insnhist
make graph_wsg_bbv_<prog>_<graph>U_sg KERNEL_ARGS="-i 5"   # bc / prspmv
make graph_wsg_bbv_<prog>_<graph>U_sg                       # ccsv / tc (full)
#   その後 SIFT (KERNEL_ARGS は BBV と一致させる)
make graph_wsg_sift_<prog>_<graph>U_sg KERNEL_ARGS="-i 5"   # bc / prspmv
make graph_wsg_sift_<prog>_<graph>U_sg                       # ccsv / tc

# prog 略称: bc / ccsv / prspmv / tc  (Makefile が cc_sv / pr_spmv に解決)
```

完了確認:
```bash
for d in graph-wsg-out/{bc,ccsv,tc,prspmv}_{road,twitter,urand,web,kron}U; do
  test -f "$d/rvv-test_v1024.0.sift" && echo "OK  $d" || echo "--  $d"
done
```

## 注意点 / リスク (Notes & Risks)

- **メモリ**: 反復制限はランタイム短縮策。グラフは kernel 開始前に全ロードされるため peak RAM は減らない → 直列必須。
- **整合性**: bc/prspmv の `-i 5` は road/web の `-i 50` 既存 SIFT と「定常代表区間」としては比較可だが、論文記載時に `-i` 差異を明記。
- **SIFT 後のテイル (要最適化)**: qemu-frontend plugin は detailed 区間取得後も exit せず**プログラム終端まで functional 実行** (line 269-273)。実測: bc_roadU(`-i 50`) は SIFT 取得後さらに **1h+** 無駄に回り続けた。
  - **早期 kill 推奨**: `<dir>/rvv-test_v1024.0.sift` が生成されサイズが ~60s 安定したら `docker stop <container>` でテイルを打ち切る (SIFT は endROI で close 済のため無傷)。重いベンチで数時間節約。
  - 恒久対策案: plugin の line 271-273 (Detail Mode End) で `exit()` するよう改修 + 再ビルド。
  - 早期 kill する場合 `make` は非0終了 → symlink を手動作成: `ln -sf rvv-test_v1024.0.sift <dir>/rvv-test_v1024.sift`
- **NFS lock**: 中断時は必ず `docker stop` → その後 `rm -rf` (open 中の `bbv.0.bb` 削除で `.nfsXXX` 残留)。
- **bfs の int64 fix** (`vecgraph.h` Readgraph_t int→int64) は新4カーネルのバイナリ(5/19ビルド)にも反映済 — twitter(2.4B edges) 完走で確認。

## 関連 (Refs)

- `graph-wsg-out/_recovery-state.md` — BBV 生成フェーズの復旧ログ
- `prave_next_retry/WORK_STATE.md` — 論文評価側の作業ログ
- `prave_next_retry/runeval_config.py` — `graphv_official_benchmarks` / `sift_dir` 定義
