---
name: health-log
description: Google ドライブのスプレッドシート「健康ログ」から血圧・心拍・睡眠・歩数の記録を読む。ユーザーが「血圧の推移は？」「最近よく寝てる？」「歩数どう？」など健康データの傾向を尋ねたときに起動する。
argument-hint: "知りたい項目・期間（省略可）"
user-invocable: true
---

# 健康ログを読む

[[health-connect-converter]] がスマホのヘルスコネクトから吸い上げ、Google ドライブのスプレッドシート「健康ログ」へ書き出したデータを読む。

**このスプレッドシートへ書き込まない。** 正本は mini-pc 上の累積 SQLite で、シートは出力先にすぎない。手で直しても次の取り込みで消える。

## タブ構成

| タブ | 中身 |
|---|---|
| `daily_summary` | 1日1行。全種別の集計を横持ち。**必ず先頭タブ** |
| `<種別>_raw` | 測定1回ごとの生データ（`blood_pressure_raw` など） |
| `_meta` | 最終成功時刻・種別ごとの件数 |

## 手順

### 1. ファイルIDを引く

`search_files` に `title contains '健康ログ'` を渡す。

### 2. 傾向を見るだけなら CSV

```
download_file_content(fileId, exportMimeType='text/csv')
```

先頭タブ `daily_summary` の全期間が返る。列は `date` と `<種別>_<関数>`（`blood_pressure_systolic_mean`・`sleep_duration_min_sum` など）。

### 3. 生データが要るなら xlsx

```
download_file_content(fileId, exportMimeType='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
```

全タブが返る。`openpyxl` でパースする（`pip install openpyxl` が要る場合がある）。

### 4. どちらも結果はファイル経由で受け取る

`download_file_content` は内容を**常に base64 で返し**、そのサイズがインライン上限を超えるためツールがファイルへ退避する。CSV も例外ではない。

1. エラーメッセージが示す退避先パスを控える
2. そのファイルは `{content, id, mimeType, title}` の JSON。`content` を base64 デコードする
3. CSV はそのまま文字列として扱い、xlsx は `.xlsx` へ書き出して開く

```python
import json, base64
d = json.load(open(退避先パス))
csv = base64.b64decode(d['content']).decode('utf-8')
```

## 注意

- **`read_file_content` を使わない。** 全タブを1文書で返して上限を超え、各タブの**先頭行から**詰めて打ち切る。出力は昇順なので**消えるのは常に直近側**になる。空振りせず古いデータが正常に返るため、壊れていることに気づけない
- **CSV は先頭タブしか返らない。** 空や別タブの内容が返ったらタブ順が崩れている。converter が毎周回で是正するので、1時間待つか mini-pc で `--once` を実行する
- **鮮度は `daily_summary` の最終行の日付で見る。** CSV 経路では `_meta` に届かない。歩数は毎日入るので、最終行が数日以上古ければ取り込みが止まっている
- **測定頻度と鮮度は別。** ある種別の値が最近入っていなくても、単に測っていないだけのことがある。「データが無い」ではなく「測定されていない」と伝える

## サイズの目安

CSV は base64 で約82,000 chars、xlsx は約410,000 chars（2026-08 時点）。`steps_raw` が xlsx の大半を占めるため、**傾向を見るだけなら CSV 経路が5倍軽く `openpyxl` も要らない。**
