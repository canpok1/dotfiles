#!/usr/bin/env bash
# workflow-scripts 共通ライブラリ（source して使う）
#
# 目的: auto-assign / auto-solve / auto-analyze を同時起動しても Todoist の
# 503（叩きすぎ）でループが落ちないようにする。
#
#   - td(): 実 td バイナリのラッパー。プロセス横断のスロットリング（最小間隔
#           を保証）と、失敗時の指数バックオフ・リトライを行う。関数名を td に
#           することで、source 側の既存 `td ...` 呼び出しをそのまま保護する。
#   - poll_sleep(): ポーリング間隔にジッターを付け、複数ループの td 呼び出しが
#           同じ瞬間に集中（同期）しないよう脱同期させる。
#
# 調整用パラメータ（環境変数で上書き可）:
#   POLL_INTERVAL      ポーリングの基準間隔（秒, 既定 300）
#   POLL_JITTER        基準間隔へ加算する 0..N 秒のランダム揺らぎ（既定 15）
#   TD_MIN_GAP         td 呼び出し間の最小間隔（秒, 全ループ横断, 既定 3）
#   TD_MAX_ATTEMPTS    td 失敗時の最大試行回数（既定 5）
#   WORKFLOW_LOCK_DIR  ロックファイルの配置先（既定 ~/.cache/workflow-scripts/locks）

# ロックは対象リポを汚さないようホーム配下に置く（全ループ横断で共有）。
WORKFLOW_LOCK_DIR="${WORKFLOW_LOCK_DIR:-${HOME}/.cache/workflow-scripts/locks}"
_LOCK_DIR="$WORKFLOW_LOCK_DIR"
mkdir -p "$_LOCK_DIR"

POLL_INTERVAL="${POLL_INTERVAL:-300}"
POLL_JITTER="${POLL_JITTER:-15}"
TD_MIN_GAP="${TD_MIN_GAP:-3}"
TD_MAX_ATTEMPTS="${TD_MAX_ATTEMPTS:-5}"

# 基準間隔 + ジッターだけ待つ。複数ループの脱同期に使う。
poll_sleep() {
  local jitter=0
  if (( POLL_JITTER > 0 )); then
    jitter=$(( RANDOM % (POLL_JITTER + 1) ))
  fi
  sleep $(( POLL_INTERVAL + jitter ))
}

# 実 td を、横断スロットリング + 指数バックオフ・リトライ付きで呼び出す。
# 既存の `td ...` 呼び出しを変更せず保護するため、あえて td という名前にする。
td() {
  local stamp="${_LOCK_DIR}/td-last" lock="${_LOCK_DIR}/td-throttle"
  local attempt=1 out rc last now wait errfile
  errfile="$(mktemp)"

  while :; do
    # 横断スロットリング: 直前の td 呼び出しから TD_MIN_GAP 秒以上空ける。
    # flock 中に待つことで、同時起動した複数ループの td が直列化・間隔保証される。
    {
      flock 8
      last="$(cat "$stamp" 2>/dev/null || echo 0)"
      now="$(date +%s)"
      wait=$(( last + TD_MIN_GAP - now ))
      if (( wait > 0 )); then
        sleep "$wait"
      fi
      date +%s > "$stamp"
    } 8>"$lock"

    if out="$(command td "$@" 2>"$errfile")"; then
      printf '%s' "$out"
      rm -f "$errfile"
      return 0
    fi
    rc=$?

    if (( attempt >= TD_MAX_ATTEMPTS )); then
      cat "$errfile" >&2
      rm -f "$errfile"
      return "$rc"
    fi
    echo "td failed (attempt ${attempt}/${TD_MAX_ATTEMPTS}); retrying with backoff..." >&2
    sleep $(( 2 ** attempt ))
    attempt=$(( attempt + 1 ))
  done
}
