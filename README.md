# setup_tools

## 概要

システムセットアップツール

本ツールは、以下のファイルを1台のホストで一元管理する際に、
複数台のホストの構築・保守作業等を支援・効率化します。

* ホスト毎にインストールするパッケージの一覧表 (以下「パッケージリスト」と記載)
* ホスト毎にカスタマイズする設定ファイルの一覧表 (以下「ファイルリスト」と記載)
* ホスト毎のカスタマイズ前の設定ファイル (以下「オリジナル設定ファイル」と記載)
* ホスト毎のカスタマイズ後の設定ファイル (以下「設定ファイル」と記載)

上記のファイルを格納する想定ディレクトリ構造は以下の通りですが、
[setup_fil.sh 用の変数定義ファイル](https://github.com/yuksiy/setup_tools/tree/master/examples)
を編集することによって、ある程度カスタマイズすることができます。  
(以下の例ではVCSを使用するディレクトリ構造になっていますが、VCSの使用は必須ではありません。)

    ${HOME}/VCS/
      setup/
        OS名(例：DebianX.X)/
          list/
            pkg_list_remote.txt (=パッケージリスト)
            file_list_remote.txt (=ファイルリスト)
          files/
            ホスト名.orig/
              any_dir/any_file (=オリジナル設定ファイル)
            ホスト名/
              any_dir/any_file (=設定ファイル)
    
    ${HOME}/VCS管理外/
      setup/
        OS名(例：DebianX.X)/
          files/
            ホスト名/
              any_dir/any_file (=VCS管理に適さず、秘密情報を含まない設定ファイル)
          files_priv/
            ホスト名/
              any_dir/any_file (=VCS管理に適さず、秘密情報を含む設定ファイル)

## 使用方法

### 「Apache」の参考セットアップ手順

パッケージリスト中のパッケージグループフィールドの値が「apache」であり、
ホストフィールドの値が「1」であるパッケージを、
リモートホストにインストールします。

    $ cd ${HOME}/VCS/setup
    $ setup_pkg_list.sh install -C ~/.setup_pkg_list.conf ./OS名/list/pkg_list_remote.txt -g apache -h ホストフィールド名 -H リモートホスト名

ファイルリスト中のパッケージグループフィールドの値が「apache」であり、
fil_import フィールドの値が「1」であり、
ホストフィールドの値が「1」である設定ファイルを、
リモートホストからローカルホストの「ホスト名.orig」ディレクトリにインポートします。

    $ setup_fil_list.sh import -C ~/.setup_fil_list.OS名.conf ./OS名/list/file_list_remote.txt -g apache -h ホストフィールド名 -H リモートホスト名

「ホスト名.orig」ディレクトリにインポートした設定ファイルを
「ホスト名」ディレクトリにコピーし、必要に応じて内容をカスタマイズします。

    $ mkdir ディレクトリ名
    $ cp コピー元ファイル名 コピー先ファイル名
    $ vi ファイル名

ファイルリスト中のパッケージグループフィールドの値が「apache」であり、
ホストフィールドの値が「1」である設定ファイルを、
ローカルホストの「ホスト名」ディレクトリからリモートホストにインストールします。

    $ setup_fil_list.sh install -C ~/.setup_fil_list.OS名.conf ./OS名/list/file_list_remote.txt -g apache -h ホストフィールド名 -H リモートホスト名

#### パッケージリスト, ファイルリストの書式

これらのファイルの書式に関しては、以下のファイルを参照してください。

* [README_pkg_list.md](https://github.com/yuksiy/setup_tools/blob/master/README_pkg_list.md)
* [README_file_list.md](https://github.com/yuksiy/setup_tools/blob/master/README_file_list.md)

### その他

* 上記で紹介したツール、および本パッケージに含まれるその他のツールの詳細については、「ツール名 --help」を参照してください。

* 現状では、本ツールの実行ホストとセットアップ対象ホストの組み合わせによって、ツールの使用可否が異なります。

本ツールの実行ホスト | セットアップ対象ホスト | ホスト種別 | setup_pkg_list.sh | setup_fil_list.sh, setup_fil.sh
-------------------- | ---------------------- | ---------- | ----------------- | -------------------------------
Linux                | Linux                  | ローカル   | ○                | ○
　                   |                        | リモート   | ○                | ○
　                   | Cygwin                 | リモート   | ×                | 未検証
Cygwin               | Cygwin                 | ローカル   | ×                | ○
　                   |                        | リモート   | ×                | 未検証
　                   | Linux                  | リモート   | ○                | ○

## 動作環境

OS:

* Linux (Debian, Fedora)
* Cygwin

依存パッケージ または 依存コマンド:

パッケージ名 または コマンド名                   | ローカルセットアップのローカルホスト | リモートセットアップのローカルホスト | リモートセットアップのリモートホスト
------------------------------------------------ | ------------------------------------ | ------------------------------------ | ------------------------------------
make (インストール目的のみ)                      | 必須                                 | 必須                                 |
openssh                                          |                                      | 必須                                 | 必須
[common_sh](https://github.com/yuksiy/common_sh) | 必須                                 | 必須                                 |
[dos_tools](https://github.com/yuksiy/dos_tools) | 必須                                 | 必須                                 |

## インストール

ソースからインストールする場合:

    (Linux, Cygwin の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

必要に応じて、
[examples/README.md ファイル](https://github.com/yuksiy/setup_tools/blob/master/examples/README.md)
を参照して変数定義ファイルをインストールしてください。

## 最新版の入手先

<https://github.com/yuksiy/setup_tools>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/setup_tools/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2011-2017 Yukio Shiiya
