scriptencoding utf-8

"�啶��/����������ʂ���
syntax case match

"���O���x��
syntax keyword logLowLevel DEBUG INFO
syntax keyword logMidLevel WARN
syntax keyword logHighLevel ERROR FATAL
highlight link logLowLevel Statement
highlight link logMidLevel Todo
highlight link logHighLevel Error

"�V���O���N�I�[�e�[�V�����ň͂܂ꂽ�烁�b�Z�[�W
"syntax region logMessage start=/'/ end=/'/
syntax match logMessage "'.*'*.*'"
highlight link logMessage Underlined
