# ファイルリストの書式

    第1フィールド    第2フィールド  …
    ---------------------------------------------
    # large_segment  pkg_group  file_name  mode  owner  group  vcs  fil_import  fil_import_src  ホストフィールド  setup_manual  remark

* 「#」で始まる行はコメント行扱いされます。

* 空行は無視されます。

* フィールド区切り文字は「タブ」とします。

* 以下のフィールドの設定値は必須設定です。
  * file_name

## # large_segment

大区分を記載します。  
(setup_fil_list.sh からは無視されます。)

## pkg_group

パッケージグループを記載します。  
setup_fil_list.sh の実行時に「-g」オプションの引数として指定することで、対象ファイルを絞り込むことができます。

## file_name

ファイル名を記載します。  
setup_fil_list.sh の実行時に「-f」オプションの引数として指定することで、対象ファイルを絞り込むことができます。

## mode, owner, group

モード, オーナー, グループを記載します。

## vcs

該当ファイルをVCSで管理する場合、「1」を記載します。  
(setup_fil_list.sh からは無視されます。  
別パッケージ「[setup_tools_options_for_vcs](https://github.com/yuksiy/setup_tools_options_for_vcs)」で使用されます。)

## fil_import

「setup_fil_list.sh import」の実行時に、file_name フィールドに記載のファイルを
「ホスト名.orig」ディレクトリにインポートする場合、「1」を記載します。  
下記の「fil_import_src」を指定する場合にも、「1」を記載してください。

## fil_import_src

「setup_fil_list.sh import」の実行時に、file_name フィールドに記載のファイルを
file_name フィールドに記載のファイル名とは異なるファイルから
「ホスト名.orig」ディレクトリにインポートする場合、そのファイル名を記載します。

## ホストフィールド

このフィールドは可変長フィールドです。  
インストール要否を記載したい数だけフィールド数を増減することができます。  
フィールドのラベルには、本ツールの利用者にとってわかりやすい文字列を記載してください。  
(想定の記載内容はホスト名ですが、「all_web_servers」「all_clients」等でも構いません。)  
そして、インストール要のファイル名の本フィールドの値として「1」を記載してください。  
setup_fil_list.sh の実行時に「-h」オプションの引数として指定することで、対象ファイルを絞り込むことができます。

## setup_manual

該当パッケージグループのセットアップ手順書が存在する場合、
その手順書のファイル名等を記載することをお奨めします。  
手順書不要のパッケージグループである場合、「-」等と記載することをお奨めします。  
setup_fil_list.sh の実行時に「-s」オプションの引数として「-」を指定することで、
手順書不要のパッケージグループのファイルだけを一括で作業対象にすることができます。

## remark

備考を記載します。  
(setup_fil_list.sh からは無視されます。)
