#!/usr/bin/env bash
# web 記事1件を obsidian-vault の clips/ へノートとして追加する。
#
# obsidian-vault のローカル clone を探し、見つかれば origin/main の先へ
# 直接 commit + push する。clone が見つからない場合は何もしない
# （work-log と同じ方針。記録するかどうかは clone の有無でユーザーが制御する）。
#
# 使い方:
#   add-clip.sh <created_time_utc> <title> <url>
#     created_time_utc: Google ドライブの createdTime（RFC3339 UTC）
#                       例: 2026-08-14T02:30:36.394Z
#     title:            ページタイトル（Drive のファイル名）
#     url:              記事の URL
#
# 終了コード:
#   0 ... ノートを作成して push した
#   2 ... 同じ URL のノートが既にあるため作成しなかった（呼び出し元は
#         Drive のファイルをゴミ箱へ移してよい）
#   1 ... エラー
#
# ファイル名の日時とノートの created は、常に JST へ変換して使う。
# 実行環境は UTC のことが多く、変換しないと JST 早朝の保存が前日扱いになる。

set -euo pipefail

VAULT_REMOTE_MATCH="canpok1/obsidian-vault"
# vault は常にこのブランチへ直接反映する。ローカル clone が別ブランチを
# チェックアウトしていても影響を受けない（work-log の append.sh と同じ）。
VAULT_TARGET_BRANCH="main"

usage() {
  echo "usage: $(basename "$0") <created_time_utc> <title> <url>" >&2
  exit 1
}

[ $# -eq 3 ] || usage
created_utc="$1"
title="$2"
url="$3"

[ -n "$title" ] || { echo "web-clip: title が空です" >&2; exit 1; }
[ -n "$url" ] || { echo "web-clip: url が空です" >&2; exit 1; }

# RFC3339 UTC を epoch 秒へ変換する。GNU date と BSD date の両方に対応する
# （クラウド実行は Linux、ホストは macOS のため）。
to_epoch() {
  local iso="$1"
  iso="${iso%Z}"
  iso="${iso%%.*}"  # 小数秒を落とす
  date -u -d "${iso}Z" '+%s' 2>/dev/null && return 0
  date -j -u -f '%Y-%m-%dT%H:%M:%S' "$iso" '+%s' 2>/dev/null && return 0
  return 1
}

# epoch 秒を JST の指定フォーマットで出力する。
epoch_fmt_jst() {
  local epoch="$1" fmt="$2"
  TZ=Asia/Tokyo date -d "@${epoch}" "+${fmt}" 2>/dev/null && return 0
  TZ=Asia/Tokyo date -r "${epoch}" "+${fmt}" 2>/dev/null && return 0
  return 1
}

# URL から ASCII の slug を作る。タイトルは日本語のことが多く、
# ファイル名に使うと環境間で扱いが揺れるため URL 側から組み立てる。
make_slug() {
  local u="$1" host path seg parent rest p slug

  u="${u#*://}"
  host="${u%%/*}"
  path="${u#"$host"}"
  host="${host##*@}"   # userinfo を除去
  host="${host%%:*}"   # ポートを除去
  host="${host#www.}"
  host="${host//./-}"

  path="${path%%\?*}"  # クエリを除去
  path="${path%%#*}"   # フラグメントを除去

  # 末尾の空でないセグメントと、その1つ上を取る
  seg=""
  parent=""
  rest="$path"
  while [ -n "$rest" ]; do
    p="${rest%%/*}"
    if [ "$rest" = "$p" ]; then rest=""; else rest="${rest#*/}"; fi
    [ -n "$p" ] || continue
    parent="$seg"
    seg="$p"
  done

  seg="${seg%.*}"  # 拡張子を除去

  # 空、または数字だけのセグメント（/articles/12345 など）は記事名にならないので
  # 1つ上のセグメントを使う
  if [ -z "$seg" ]; then
    seg="$parent"
  else
    case "$seg" in
      *[!0-9]*) ;;
      *) seg="$parent" ;;
    esac
  fi

  slug="${host}-${seg}"
  slug="$(printf '%s' "$slug" \
    | LC_ALL=C tr '[:upper:]' '[:lower:]' \
    | LC_ALL=C sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-*//' -e 's/-*$//')"
  slug="$(printf '%s' "$slug" | cut -c1-64 | LC_ALL=C sed -e 's/-*$//')"

  [ -n "$slug" ] || slug="clip"
  printf '%s' "$slug"
}

# clone の置き場所の候補を優先度順に出力する（append.sh と同じ探し方）。
vault_dir_candidates() {
  [ -n "${OBSIDIAN_VAULT_DIR:-}" ] && printf '%s\n' "$OBSIDIAN_VAULT_DIR"

  local proj_root
  if proj_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "$(dirname "$proj_root")/obsidian-vault"
  fi

  printf '%s\n' "$HOME/obsidian-vault" "$HOME/src/obsidian-vault"
}

find_vault_dir() {
  local dir
  while IFS= read -r dir; do
    [ -d "$dir/.git" ] || continue
    if git -C "$dir" remote get-url origin 2>/dev/null | grep -qF "$VAULT_REMOTE_MATCH"; then
      printf '%s' "$dir"
      return 0
    fi
  done < <(vault_dir_candidates | awk '!seen[$0]++')
  return 1
}

# clone のチェックアウト状態や作業ツリーには触れず、git plumbing だけで
# origin/main の先にコミットを作って push する。
add_clip() {
  local vault_dir="$1" ts_jst="$2" date_jst="$3" slug="$4"
  local attempt=1 max_attempts=3

  while :; do
    if ! git -C "$vault_dir" fetch origin "$VAULT_TARGET_BRANCH" --quiet; then
      echo "web-clip: git fetch に失敗しました" >&2
      return 1
    fi

    local base_sha
    base_sha="$(git -C "$vault_dir" rev-parse "origin/${VAULT_TARGET_BRANCH}")"

    # 同じ URL のノートが既にあれば作らない。frontmatter の url 行と完全一致で見る
    if git -C "$vault_dir" grep -q -F -e "url: ${url}" "$base_sha" -- 'clips/*.md' 2>/dev/null; then
      return 2
    fi

    # ファイル名が衝突したら連番で回避する
    local path n=1
    path="clips/${ts_jst}-${slug}.md"
    while git -C "$vault_dir" cat-file -e "${base_sha}:${path}" 2>/dev/null; do
      n=$((n + 1))
      path="clips/${ts_jst}-${slug}-${n}.md"
    done

    local note
    note="---
title: ${title}
url: ${url}
created: ${date_jst}
---

# ${title}

${url}"

    local tmp_index
    tmp_index="$(mktemp)"
    GIT_INDEX_FILE="$tmp_index" git -C "$vault_dir" read-tree "$base_sha"

    local blob
    blob="$(printf '%s\n' "$note" | git -C "$vault_dir" hash-object -w --stdin)"
    GIT_INDEX_FILE="$tmp_index" git -C "$vault_dir" update-index --add --cacheinfo "100644,${blob},${path}"

    local new_tree new_commit
    new_tree="$(GIT_INDEX_FILE="$tmp_index" git -C "$vault_dir" write-tree)"
    rm -f "$tmp_index"

    new_commit="$(git -C "$vault_dir" commit-tree "$new_tree" -p "$base_sha" -m "web-clip: ${title}")"

    local push_err
    if push_err="$(git -C "$vault_dir" push origin "${new_commit}:refs/heads/${VAULT_TARGET_BRANCH}" --quiet 2>&1)"; then
      printf '%s\n' "$path"
      return 0
    fi

    if [ "$attempt" -lt "$max_attempts" ] && printf '%s' "$push_err" | grep -qE 'rejected|non-fast-forward|fetch first|stale info'; then
      attempt=$((attempt + 1))
      continue
    fi

    printf '%s\n' "$push_err" >&2
    return 1
  done
}

epoch="$(to_epoch "$created_utc")" || {
  echo "web-clip: 日時を解釈できませんでした: ${created_utc}" >&2
  exit 1
}
ts_jst="$(epoch_fmt_jst "$epoch" '%Y%m%d%H%M%S')"
date_jst="$(epoch_fmt_jst "$epoch" '%F')"
slug="$(make_slug "$url")"

# vault へ触らずに、日時変換と slug の結果だけ確認するための逃げ道
if [ -n "${WEB_CLIP_DRY_RUN:-}" ]; then
  echo "ts_jst=${ts_jst} date_jst=${date_jst} slug=${slug} path=clips/${ts_jst}-${slug}.md"
  exit 0
fi

if ! vault_dir="$(find_vault_dir)"; then
  echo "web-clip: obsidian-vault の clone が見つからないため、取り込みをスキップしました" >&2
  exit 0
fi

set +e
created_path="$(add_clip "$vault_dir" "$ts_jst" "$date_jst" "$slug")"
rc=$?
set -e

if [ "$rc" -eq 0 ]; then
  echo "created: ${created_path}"
  exit 0
fi

if [ "$rc" -eq 2 ]; then
  echo "skipped (duplicate): ${url}" >&2
fi
exit "$rc"
