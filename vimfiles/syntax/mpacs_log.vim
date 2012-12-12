scriptencoding utf-8

"大文字/小文字を区別する
syntax case match

"ログレベル
syntax keyword logLowLevel DEBUG INFO
syntax keyword logMidLevel WARN
syntax keyword logHighLevel ERROR FATAL
highlight link logLowLevel Statement
highlight link logMidLevel Todo
highlight link logHighLevel Error

"シングルクオーテーションで囲まれたらメッセージ
"syntax region logMessage start=/'/ end=/'/
syntax match logMessage "'.*'*.*'"
highlight link logMessage Underlined
