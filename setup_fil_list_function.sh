#!/bin/sh

# ==============================================================================
#   機能
#     setup_fil_list.sh 用の関数定義ファイル
#   構文
#     . setup_fil_list_function.sh
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
LABEL_FILE_NAME='file_name'
LABEL_PKG_GROUP='pkg_group'
LABEL_MODE='mode'
LABEL_OWNER='owner'
LABEL_GROUP='group'
LABEL_VCS='vcs'
LABEL_FIL_IMPORT='fil_import'
LABEL_FIL_IMPORT_SRC='fil_import_src'
LABEL_SETUP_MANUAL='setup_manual'

FIELD_FILE_NAME=""						#初期状態が「空文字」でなければならない変数
FIELD_PKG_GROUP=""						#初期状態が「空文字」でなければならない変数
FIELD_MODE=""							#初期状態が「空文字」でなければならない変数
FIELD_OWNER=""							#初期状態が「空文字」でなければならない変数
FIELD_GROUP=""							#初期状態が「空文字」でなければならない変数
FIELD_VCS=""							#初期状態が「空文字」でなければならない変数
FIELD_FIL_IMPORT=""						#初期状態が「空文字」でなければならない変数
FIELD_FIL_IMPORT_SRC=""					#初期状態が「空文字」でなければならない変数
FIELD_HOST=""							#初期状態が「空文字」でなければならない変数
FIELD_SETUP_MANUAL=""					#初期状態が「空文字」でなければならない変数

FILE_NAME=""							#初期状態が「空文字」でなければならない変数
PKG_GROUP=""							#初期状態が「空文字」でなければならない変数
MODE=""									#初期状態が「空文字」でなければならない変数
OWNER=""								#初期状態が「空文字」でなければならない変数
GROUP=""								#初期状態が「空文字」でなければならない変数
VCS=""									#初期状態が「空文字」でなければならない変数
FIL_IMPORT=""							#初期状態が「空文字」でなければならない変数
FIL_IMPORT_SRC=""						#初期状態が「空文字」でなければならない変数
HOST=""									#初期状態が「空文字」でなければならない変数
SETUP_MANUAL=""							#初期状態が「空文字」でなければならない変数

TMP_FIELD_FILE_NAME=1
TMP_FIELD_MODE=2
TMP_FIELD_OWNER=3
TMP_FIELD_GROUP=4
TMP_FIELD_VCS=5
TMP_FIELD_FIL_IMPORT=6
TMP_FIELD_FIL_IMPORT_SRC=7

######################################################################
# 関数定義
######################################################################
# ファイルリスト中の各種フィールドの検索
FILE_LIST_FIELD_SEARCH() {
	IFS_SAVE=${IFS}
	IFS='	'
	field_count=0
	for field in `cat "${FILE_LIST}" | sed -n "s/^#[# ]*\(.*${LABEL_FILE_NAME}.*\)$/\1/p" | head -1` ; do
		field_count=`expr ${field_count} + 1`
		if [ "${field}" = "${LABEL_FILE_NAME}" ];then
			FIELD_FILE_NAME=${field_count}
		elif [ "${field}" = "${LABEL_PKG_GROUP}" ];then
			FIELD_PKG_GROUP=${field_count}
		elif [ "${field}" = "${LABEL_MODE}" ];then
			FIELD_MODE=${field_count}
		elif [ "${field}" = "${LABEL_OWNER}" ];then
			FIELD_OWNER=${field_count}
		elif [ "${field}" = "${LABEL_GROUP}" ];then
			FIELD_GROUP=${field_count}
		elif [ "${field}" = "${LABEL_VCS}" ];then
			FIELD_VCS=${field_count}
		elif [ "${field}" = "${LABEL_FIL_IMPORT}" ];then
			FIELD_FIL_IMPORT=${field_count}
		elif [ "${field}" = "${LABEL_FIL_IMPORT_SRC}" ];then
			FIELD_FIL_IMPORT_SRC=${field_count}
		elif [ \( ! "${HOST}" = "" \) -a \( "${field}" = "${HOST}" \) ];then
			FIELD_HOST=${field_count}
		elif [ "${field}" = "${LABEL_SETUP_MANUAL}" ];then
			FIELD_SETUP_MANUAL=${field_count}
		fi
	done
	IFS=${IFS_SAVE}
	unset IFS_SAVE
	if [ "${FIELD_FILE_NAME}" = "" ];then
		echo "-E FILE_NAME field not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ \( ! "${PKG_GROUP}" = "" \) -a \( "${FIELD_PKG_GROUP}" = "" \) ];then
		echo "-E PKG_GROUP field not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ "${FIELD_MODE}" = "" ];then
		echo "-E MODE field not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ "${FIELD_OWNER}" = "" ];then
		echo "-E OWNER field not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ "${FIELD_GROUP}" = "" ];then
		echo "-E GROUP field not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ "${FIELD_VCS}" = "" ];then
		echo "-E VCS field not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ "${FIELD_FIL_IMPORT}" = "" ];then
		echo "-E FIL_IMPORT field not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ "${FIELD_FIL_IMPORT_SRC}" = "" ];then
		echo "-E FIL_IMPORT_SRC field not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ \( ! "${HOST}" = "" \) -a \( "${FIELD_HOST}" = "" \) ];then
		echo "-E HOST field \"${HOST}\" not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
	if [ \( ! "${SETUP_MANUAL}" = "" \) -a \( "${FIELD_SETUP_MANUAL}" = "" \) ];then
		echo "-E SETUP_MANUAL field not found in FILE_LIST -- \"${FILE_LIST}\"" 1>&2
		POST_PROCESS;exit 1
	fi
}

# 作業用ファイルリストの作成
FILE_LIST_TMP_MAKE() {
	awk -F '\t' \
		-v FIELD_FILE_NAME="${FIELD_FILE_NAME}" -v FIELD_PKG_GROUP="${FIELD_PKG_GROUP}" \
		-v FIELD_MODE="${FIELD_MODE}" -v FIELD_OWNER="${FIELD_OWNER}" -v FIELD_GROUP="${FIELD_GROUP}" \
		-v FIELD_VCS="${FIELD_VCS}" \
		-v FIELD_FIL_IMPORT="${FIELD_FIL_IMPORT}" -v FIELD_FIL_IMPORT_SRC="${FIELD_FIL_IMPORT_SRC}" \
		-v FIELD_HOST="${FIELD_HOST}" -v FIELD_SETUP_MANUAL="${FIELD_SETUP_MANUAL}" \
		-v FILE_NAME="${FILE_NAME}" -v PKG_GROUP="${PKG_GROUP}" \
		-v VCS="${VCS}" -v FIL_IMPORT="${FIL_IMPORT}" \
		-v HOST="${HOST}" -v SETUP_MANUAL="${SETUP_MANUAL}" \
	'{
		# コメントまたは空行でない場合
		if ($0 !~/^#/ && $0 !~/^[\t ]*$/) {
			# 必須フィールドのチェック
			if ($FIELD_FILE_NAME ~/^$/) {
				system(sprintf("echo 1>&2"))
				system(sprintf("echo \042-E Omitted required field at line %s -- \134\042${FILE_LIST}\134\042\042 1>&2" ,NR))
				system(sprintf("echo \047%s\047 1>&2" ,$0))
				exit 1
			}

			# ファイル名フィールドのチェック
			if (FILE_NAME != "") {
				if ($FIELD_FILE_NAME != FILE_NAME) {
					next
				}
			}

			# パッケージグループフィールドのチェック
			if (PKG_GROUP != "") {
				if ($FIELD_PKG_GROUP != PKG_GROUP) {
					next
				}
			}

			# vcs フィールドのチェック
			if (VCS != "") {
				if ($FIELD_VCS != VCS) {
					next
				}
			}

			# fil_import フィールドのチェック
			if (FIL_IMPORT != "") {
				if ($FIELD_FIL_IMPORT != FIL_IMPORT) {
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

			# ファイルリストエントリの出力
			printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\n", \
				$FIELD_FILE_NAME, $FIELD_MODE, $FIELD_OWNER, $FIELD_GROUP, \
				$FIELD_VCS, $FIELD_FIL_IMPORT, $FIELD_FIL_IMPORT_SRC \
			)
		}
	}' "${FILE_LIST}" \
	> "${FILE_LIST_TMP}"
	if [ $? -ne 0 ];then
		POST_PROCESS;exit 1
	fi
}

