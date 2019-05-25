dotfiles
========

各種設定ファイルを管理しています。

## （初回のみ）初期設定の方法

よく使うアプリのインストールとPC設定変更、設定ファイルの展開を行います。

1. githubからファイルを取得

    ```
    git clone http://github.com/canpok1/dotfiles.git ~/dotfiles
    ```

2. スクリプト実行

    * Windows

        ```
        setup.bat
        ```

    * Mac、Linux

        ```
        ./setup.sh --init
        ```

## 設定ファイルの展開方法

設定ファイルのみを再度展開します。
設定ファイルを削除してしまった時などに実行します。

1. スクリプトを実行

    * Windows

        ```
        setup.bat
        ```

    * Mac、Linux

        ```
        ./setup.sh
        ```

## 設定ファイルの削除方法

1. セットアップスクリプトを実行

    * Windows

        * スクリプトを用意してません。

    * Mac、Linux

        ```
        ./setup.sh --undeploy
        ```

2. dotfilesフォルダを削除

