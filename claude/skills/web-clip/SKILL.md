---
name: web-clip
description: Google ドライブのフォルダ「webクリップ」に溜まった web 記事を、obsidian-vault の clips/ へ1記事1ノートで取り込む。スマホから共有した記事の回収に使う。ユーザーが「webクリップ取り込んで」「記事を回収して」と言ったときや、定期実行の Routine から起動する。
allowed-tools: Bash, Read
user-invocable: true
---

# web クリップを Obsidian に取り込む

スマホ（Android）の共有シートから Google ドライブへ保存した web 記事を、[[obsidian-vault]] の `clips/` へ転記する。判断の経緯は `dotfiles/docs/adr/0009-web-clip-inbox-via-google-drive.md` にある。

保存されるファイルは Chrome の共有が作るもので、次の形をしている。

| 項目 | 内容 |
|---|---|
| `mimeType` | `text/plain` |
| `title` | ページタイトル |
| 中身 | URL 1行のみ |
| `createdTime` | 共有した日時（UTC） |

## 前提

- Google ドライブのコネクタが使えること。使えない場合はこのスキルは動かない
- obsidian-vault のローカル clone があること。無い場合は `add-clip.sh` が何もせず正常終了する（`work-log` と同じ方針）

## 起動のしかた

基本はユーザーの依頼による手動起動（「webクリップ取り込んで」）。

定期実行にする場合、**Routine は claude.ai の Routines UI から作る必要がある。** Claude が MCP 経由で作った Routine にはコネクタが載らず、発火したセッションから Drive を読めない（2026-08-14 に実測して確認済み。トリガー作成時にサーバも `this trigger stores no MCP connectors` と警告する）。UI から作る場合は Google ドライブのコネクタを有効にしたうえで、毎朝 8:00 JST（UTC の cron で `0 23 * * *`）に新しいセッションを起こす形にする。

## 手順

### 1. 受け皿のフォルダを探す

フォルダは **名前で解決する**。id を埋め込むと、フォルダを作り直したときに動かなくなる。

```
search_files: title = 'webクリップ' and mimeType = 'application/vnd.google-apps.folder'
```

見つからない場合はユーザーへ「フォルダ『webクリップ』が見つからない」と伝えて終了する。勝手に作らない（別の場所に作ると、スマホからの保存先とずれたまま気付けない）。

### 2. フォルダ直下のファイルを列挙する

```
search_files: parentId = '<フォルダのid>' and mimeType != 'application/vnd.google-apps.folder'
```

**0件なら何もせず終了する。** これは正常系であり、報告もコミットも不要。

### 3. 1件ずつ取り込む

各ファイルについて次を行う。

1. `download_file_content` で中身を取得し、base64 をデコードして URL を得る
    - `search_files` の `contentSnippet` は長い内容だと切り詰められるため、URL の取得には使わない
    - デコード結果の前後の空白と改行を落とす
2. 中身が `http://` か `https://` で始まらない場合は**取り込まず、Drive のファイルも消さない**。件数だけ数えて最後に報告する（想定外の共有が入った可能性があるため、ユーザーが中身を見られる状態で残す）
3. ノートを作る

    ```bash
    ~/.claude/skills/web-clip/scripts/add-clip.sh "<createdTime>" "<title>" "<URL>"
    ```

    - 第1引数: Drive の `createdTime` をそのまま渡す（RFC3339 UTC）。JST への変換はスクリプトが行う
    - 第2引数: Drive の `title`（ページタイトル）
    - 第3引数: 取り出した URL
    - 終了コード 0 … ノートを作成して `main` へ push した。作成したパスを標準出力に出す
    - 終了コード 2 … 同じ URL のノートが既にあるため作成しなかった
    - 終了コード 1 … エラー
4. 終了コードが **0 または 2 のときだけ** `trash_file` で Drive のファイルをゴミ箱へ移す
    - 2（重複）でも消す。vault 側に既に記録があり、Drive に残す意味がないため
    - 1（エラー）のときは消さない。次回の実行で拾い直せるようにする

### 4. 結果を報告する

取り込んだ件数、重複でスキップした件数、URL でなかった件数、エラーの件数を1行でまとめる。作成したノートのタイトルを併記する。

## 注意

- **作業記録（`work-log`）は残さない。** 毎日走る定常運用であり、デイリーノートのノイズになる
- **`clips/` へ手で書かない。** ファイル名の日時と slug の規則はスクリプトが持っている
- スクリプトは vault の作業ツリーに触れず、git plumbing で `origin/main` の先へ直接 commit + push する。clone が別ブランチをチェックアウトしていても干渉しない
- 呼び出しには配布先の `~/.claude/` 配下のパスを使う。このスキル自身がそこから読み込まれているため必ず存在する

## ノートの形

```markdown
---
title: なぜAI時代にGoが最適な言語なのか
url: https://zenn.dev/iwatsukayura/articles/google-go-ai
created: 2026-08-14
---

# なぜAI時代にGoが最適な言語なのか

https://zenn.dev/iwatsukayura/articles/google-go-ai
```

ファイル名は `clips/YYYYMMDDHHMMSS-<slug>.md`。日時は `createdTime` を JST へ変換したもの、slug は URL から組み立てた ASCII 文字列で、`ホスト名-末尾セグメント` を基本とする。

## 動作確認

vault に触れずに、日時変換と slug だけを確認できる。

```bash
WEB_CLIP_DRY_RUN=1 ~/.claude/skills/web-clip/scripts/add-clip.sh \
  "2026-08-14T02:30:36.394Z" "タイトル" "https://zenn.dev/iwatsukayura/articles/google-go-ai"
# => ts_jst=20260814113036 date_jst=2026-08-14 slug=zenn-dev-google-go-ai path=clips/20260814113036-zenn-dev-google-go-ai.md
```
