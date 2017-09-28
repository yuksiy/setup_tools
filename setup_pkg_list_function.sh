#!/bin/sh

# ==============================================================================
#   機能
#     setup_pkg_list.sh 用の関数定義ファイル
#   構文
#     . setup_pkg_list_function.sh
#
#   Copyright (c) 2011-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 変数定義
######################################################################
# プログラム内部変数
LABEL_PKG_NAME='pkg_name'
LABEL_PKG_NAME_FULL='pkg_name_full'
LABEL_TARGET_RELEASE='target_release'
LABEL_PKG_GROUP='pkg_group'
LABEL_SETUP_MANUAL='setup_manual'

FIELD_PKG_NAME=""						#初期状態が「空文字」でなければならない変数
FIELD_PKG_NAME_FULL=""					#初期状態が「空文字」でなければならない変数
FIELD_TARGET_RELEASE=""					#初期状態が「空文字」でなければならない変数
FIELD_PKG_GROUP=""						#初期状態が「空文字」でなければならない変数
FIELD_HOST=""							#初期状態が「空文字」でなければならない変数
FIELD_SETUP_MANUAL=""					#初期状態が「空文字」でなければならない変数

PKG_GROUP=""							#初期状態が「空文字」でなければならない変数
HOST=""									#初期状態が「空文字」でなければならない変数
SETUP_MANUAL=""							#初期状態が「空文字」でなければならない変数

######################################################################
# 関数定義
######################################################################
# パッケージリスト中の各種フィールドの検索
PKG_LIST_FIELD_SEARCH() {
	IFS_SAVE=${IFS}
	IFS='	'
	field_count=0
	for field in `cat "${PKG_LIST}" | sed -n "s/^#[# ]*\(.*${LABEL_PKG_NAME}.*\)$/\1/p" | head -1` ; do
		field_count=`expr ${field_count} + 1`
		if [ "${field}" = "${LABEL_PKG_NAME}" ];then
			FIELD_PKG_NAME=${field_count}
		elif [ "${field}" = "${LABEL_PKG_NAME_FULL}" ];then
			FIELD_PKG_NAME_FULL=${field_count}
		elif [ "${field}" = "${LABEL_TARGET_RELEASE}" ];then
			FIELD_TARGET_RELEASE=${field_count}
		elif [ "${field}" = "${LABEL_PKG_GROUP}" ];then
			FIELD_PKG_GROUP=${field_count}
		elif [ \( ! "${HOST}" = "" \) -a \( "${field}" = "${HOST}" \) ];then
			FIELD_HOST=${field_count}
		elif [ "${field}" = "${LABEL_SETUP_MANUAL}" ];then
			FIELD_SETUP_MANUAL=${field_count}
		fi
	done
	IFS=${IFS_SAVE}
	unset IFS_SAVE
	if [ "${FIELD_PKG_NAME}" = "" ];then
		echo "-E PKG_NAME field not found in PKG_LIST -- \"${PKG_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ \( ! "${PKG_GROUP}" = "" \) -a \( "${FIELD_PKG_GROUP}" = "" \) ];then
		echo "-E PKG_GROUP field not found in PKG_LIST -- \"${PKG_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ \( ! "${HOST}" = "" \) -a \( "${FIELD_HOST}" = "" \) ];then
		echo "-E HOST field \"${HOST}\" not found in PKG_LIST -- \"${PKG_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ \( ! "${SETUP_MANUAL}" = "" \) -a \( "${FIELD_SETUP_MANUAL}" = "" \) ];then
		echo "-E SETUP_MANUAL field not found in PKG_LIST -- \"${PKG_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
}

# 作業用パッケージリストの作成
PKG_LIST_TMP_MAKE() {
	awk -F '\t' \
		-v PKG_SYSTEM="${PKG_SYSTEM}" \
		-v FIELD_PKG_NAME="${FIELD_PKG_NAME}" \
		-v FIELD_PKG_NAME_FULL="${FIELD_PKG_NAME_FULL}" \
		-v FIELD_TARGET_RELEASE="${FIELD_TARGET_RELEASE}" \
		-v FIELD_PKG_GROUP="${FIELD_PKG_GROUP}" \
		-v FIELD_HOST="${FIELD_HOST}" \
		-v FIELD_SETUP_MANUAL="${FIELD_SETUP_MANUAL}" \
		-v PKG_GROUP="${PKG_GROUP}" \
		-v HOST="${HOST}" \
		-v SETUP_MANUAL="${SETUP_MANUAL}" \
	'{
		# コメントまたは空行でない場合
		if ($0 !~/^#/ && $0 !~/^[\t ]*$/) {
			# 必須フィールドのチェック
			if ($FIELD_PKG_NAME ~/^$/) {
				system(sprintf("echo 1>&2"))
				system(sprintf("echo \042-E Omitted required field at line %s -- \134\042${PKG_LIST}\134\042\042 1>&2" ,NR))
				system(sprintf("echo \047%s\047 1>&2" ,$0))
				exit 1
			} else {
				pkg_name=$FIELD_PKG_NAME
			}

			# 完全パッケージ名フィールドのチェック
			if (FIELD_PKG_NAME_FULL == "") {
				pkg_name_full=""
			} else {
				pkg_name_full=$FIELD_PKG_NAME_FULL
			}

			# ターゲットリリースフィールドのチェック
			if (FIELD_TARGET_RELEASE == "") {
				target_release=""
			} else {
				target_release=$FIELD_TARGET_RELEASE
			}

			# パッケージグループフィールドのチェック
			if (PKG_GROUP != "") {
				if ($FIELD_PKG_GROUP != PKG_GROUP) {
					next
				}
			}

			# ホストフィールドのチェック
			if (HOST != "") {
				if ($FIELD_HOST != "1") {
					next
				}
			}

			# セットアップマニュアルフィールドのチェック
			if (SETUP_MANUAL != "") {
				if ($FIELD_SETUP_MANUAL != SETUP_MANUAL) {
					next
				}
			}

			# パッケージリストエントリの出力
			if (PKG_SYSTEM == "apt") {
				printf("%-47s %s\n", pkg_name, target_release)
			} else if (PKG_SYSTEM == "dnf") {
				printf("%s\n", pkg_name)
			}
		}
	}' "${PKG_LIST}" \
	> "${PKG_LIST_TMP}"
	if [ $? -ne 0 ];then
		POST_PROCESS;exit 1
	fi
}

# 作業用パッケージ情報表示スクリプトの作成
PKG_SHOW_SCRIPT_TMP_MAKE() {
	cat /dev/null > "${PKG_SCRIPT_TMP}"
	chmod 0755      "${PKG_SCRIPT_TMP}"
	case ${PKG_SYSTEM} in
	apt)
		cmd_line="apt-cache show"
		;;
	dnf)
		cmd_line="dnf info"
		;;
	esac
	case ${PKG_SYSTEM} in
	apt|dnf)
		cat <<- EOF > "${PKG_SCRIPT_TMP}"
			#!/bin/sh
			PKG_LIST_TMP="\$1"
			cmd_line="${cmd_line}"
			for pkg_name in \`awk '{print \$1}' "\${PKG_LIST_TMP}"\` ; do
				\${cmd_line} \${pkg_name}
				RC=\$?
				if [ \${RC} -ne 0 ];then
					return \${RC}
				fi
			done
		EOF
		;;
	esac
}

# 作業用パッケージインストールスクリプトの作成
PKG_INST_SCRIPT_TMP_MAKE() {
	cat /dev/null > "${PKG_SCRIPT_TMP}"
	chmod 0755      "${PKG_SCRIPT_TMP}"
	case ${PKG_SYSTEM} in
	apt)
		cat <<- EOF > "${PKG_SCRIPT_TMP}"
			#!/bin/sh
			PKG_LIST_TMP="\$1"
			for target_release in \`cat "\${PKG_LIST_TMP}" | awk '{print "x"\$2}' | sort | uniq\` ; do
				target_release="\$(echo "\${target_release}" | sed 's#^x##')"
				pkg_list_tmp_tmp="\${PKG_LIST_TMP}.tmp\${target_release:+.\${target_release}}"
				cmd_line="apt-get \${target_release:+-t \${target_release} }install"
				echo
				echo "-I target_release=\"\${target_release}\""
				awk \
					-v target_release="\${target_release}" \
				'{
					if (\$2 == target_release) {
						print \$1
					}
				}' "\${PKG_LIST_TMP}" \
				>  "\${pkg_list_tmp_tmp}"
				xargs -a "\${pkg_list_tmp_tmp}" -r -t \${cmd_line}
				RC=\$?
				if [ \${RC} -ne 0 ];then
					return \${RC}
				fi
			done
		EOF
		;;
	dnf)
		cat <<- EOF > "${PKG_SCRIPT_TMP}"
			#!/bin/sh
			PKG_LIST_TMP="\$1"
			CMD_LINE="dnf install"
			xargs -a "\${PKG_LIST_TMP}" -r -t \${CMD_LINE}
			RC=\$?
			if [ \${RC} -ne 0 ];then
				return \${RC}
			fi
		EOF
		;;
	esac
}

