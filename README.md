dotfiles
========

各種設定ファイルを管理しています。

## 設定ファイルの展開方法

1. githubからファイルを持ってくる

    ```
    git clone http://github.com/canpok1/dotfiles.git ~/dotfiles
    ```

2. 初期設定スクリプトを実行

    必要アプリのインストールとPC設定の変更を行います。
    不要な場合はスキップしてください。

    * Windows

        * スクリプトはありません

    * Mac、Linux

        ```
        ./setup.sh --init
        ```

3. セットアップスクリプトを実行

    設定ファイルを展開します。

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

