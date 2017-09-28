#!/bin/sh

# ==============================================================================
#   機能
#     ファイルリストに従ってファイルの操作を実行する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2011-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
trap "" 28				# TRAP SET
trap "POST_PROCESS;exit 1" 1 2 15	# TRAP SET

SCRIPT_NAME="`basename $0`"
PID=$$

######################################################################
# 変数定義
######################################################################
# ユーザ変数
HOSTNAME=`hostname`

REMOTE_UNAME="root"

SETUP_FIL_OPTIONS=""

# システム環境 依存変数
case `uname -s` in
FreeBSD)
	GETOPT="/usr/local/bin/getopt"
	;;
*)
	GETOPT="getopt"
	;;
esac

# プログラム内部変数
HOST_DIR=""								#初期状態が「空文字」でなければならない変数
REMOTE_HOST="${HOSTNAME}"
PKG_GROUP=""							#初期状態が「空文字」でなければならない変数
FILE_NAME=""							#初期状態が「空文字」でなければならない変数
HOST=""									#初期状態が「空文字」でなければならない変数
SETUP_MANUAL=""							#初期状態が「空文字」でなければならない変数
VERBOSITY="1"
USE_SSHFS="no"
SSHFS_OPTIONS=""

ROOT=""									#初期状態が「空文字」でなければならない変数
FIL_IMPORT=""							#初期状態が「空文字」でなければならない変数

CONFIG_FILE="${HOME}/.setup_fil_list.conf"
# # 変数定義ファイルの読み込み
# if [ -f "${CONFIG_FILE}" ];then
# 	. "${CONFIG_FILE}"
# fi

#DEBUG=TRUE
TMP_DIR="/tmp"
SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}.${PID}"
FILE_LIST_TMP="${SCRIPT_TMP_DIR}/file_list.tmp"
MNT_TMP_DIR="${SCRIPT_TMP_DIR}/mnt"

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	# 一時ディレクトリの作成
	mkdir -p "${SCRIPT_TMP_DIR}"
	# sshfsを使用する場合
	if [ ! "${REMOTE_HOST}" = "${HOSTNAME}" ];then
		if [ "${USE_SSHFS}" = "yes" ];then
			# 変数定義
			ROOT="${MNT_TMP_DIR}/${REMOTE_HOST}"
			# リモートファイルシステムのマウント一時ディレクトリの作成
			mkdir -m 0700 "${MNT_TMP_DIR}"
			mkdir "${ROOT}"
			# リモートファイルシステムのマウント
			cmd_line="sshfs ${SSHFS_OPTIONS} ${REMOTE_UNAME}@${REMOTE_HOST}:/ ${ROOT}"
			CMD_V "${cmd_line}"
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				POST_PROCESS;exit 1
			fi
		fi
	fi
}

POST_PROCESS() {
	# sshfsを使用する場合
	if [ ! "${REMOTE_HOST}" = "${HOSTNAME}" ];then
		if [ "${USE_SSHFS}" = "yes" ];then
			# リモートファイルシステムのマウント解除
			cmd_line="fusermount -u ${ROOT}"
			CMD_V "${cmd_line}"
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				#POST_PROCESS;exit 1
			fi
		fi
	fi
	# 一時ディレクトリの削除
	if [ ! ${DEBUG} ];then
		rm -fr "${SCRIPT_TMP_DIR}"
	fi
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    setup_fil_list.sh ACTION [OPTIONS ...] [ARGUMENTS ...]
		
		ACTIONS:
		    import [OPTIONS ...] FILE_LIST
		       Import files.
		    install [OPTIONS ...] FILE_LIST
		       Install files.
		
		ARGUMENTS:
		    FILE_LIST : Specify an file list.
		
		OPTIONS:
		    --setup_fil_options="SETUP_FIL_OPTIONS ..."
		       Specify options which execute setup_fil.sh command with.
		       See also "setup_fil.sh --help" for the further information on each
		       option.
		       (Available with: import, install)
		    --hd=HOST_DIR
		       Specify host directory if it differs from the remote host name.
		       (Available with: import, install)
		    -C CONFIG_FILE
		       Specify a config file.
		       (Available with: import, install)
		    -H REMOTE_HOST
		       Specify remote host name.
		       (Available with: import, install)
		    -g PKG_GROUP
		       Specify package group field value in FILE_LIST.
		       (Available with: import, install)
		    -f FILE_NAME
		       Specify file name field value in FILE_LIST.
		       (Available with: import, install)
		    -h HOST
		       Specify host field name in FILE_LIST.
		       (Available with: import, install)
		    -s SETUP_MANUAL
		       Specify setup manual field value in FILE_LIST.
		       (Available with: import, install)
		    -v {0|1}
		       Specify output verbosity.
		       (Available with: import, install)
		    --use-sshfs={yes|no}
		       Use sshfs to speed up actions to remote host.
		       (Available with: import, install)
		    --sshfs-options="SSHFS_OPTIONS ..."
		       Specify options which execute sshfs command with.
		       See also sshfs(1) for the further information on each option.
		       (Available with: import, install)
		    --help
		       Display this help and exit.
	EOF
}

. yesno_function.sh

. setup_common_function.sh
. setup_fil_list_function.sh

######################################################################
# メインルーチン
######################################################################

# ACTIONのチェック
if [ "$1" = "" ];then
	echo "-E Missing ACTION" 1>&2
	USAGE;exit 1
else
	case "$1" in
	import|install)
		ACTION="$1"
		;;
	*)
		echo "-E Invalid ACTION -- \"$1\"" 1>&2
		USAGE;exit 1
		;;
	esac
fi

# ACTIONをシフト
shift 1

# オプションのチェック
CMD_ARG="`${GETOPT} -o C:H:g:f:h:s:v: -l setup_fil_options:,hd:,use-sshfs:,sshfs-options:,help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	--setup_fil_options)	SETUP_FIL_OPTIONS="$2" ; shift 2;;
	--hd)	HOST_DIR="$2" ; shift 2;;
	-C)
		CONFIG_FILE="$2" ; shift 2
		# 変数定義ファイルの読み込み
		if [ ! -f "${CONFIG_FILE}" ];then
			echo "-E CONFIG_FILE not a file -- \"${CONFIG_FILE}\"" 1>&2
			USAGE;exit 1
		else
			. "${CONFIG_FILE}"
		fi
		;;
	-H)	REMOTE_HOST="$2" ; shift 2;;
	-g)	PKG_GROUP="$2" ; shift 2;;
	-f)	FILE_NAME="$2" ; shift 2;;
	-h)	HOST="$2" ; shift 2;;
	-s)	SETUP_MANUAL="$2" ; shift 2;;
	-v)
		case "$2" in
		0|1)	VERBOSITY="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE;exit 1
			;;
		esac
		;;
	--use-sshfs)
		case "$2" in
		yes|no)
			case "${opt}" in
			--use-sshfs)	USE_SSHFS="$2" ; shift 2;;
			esac
			;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--sshfs-options)	SSHFS_OPTIONS="$2" ; shift 2;;
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 引数のチェック
case ${ACTION} in
import|install)
	# 第1引数のチェック
	if [ "$1" = "" ];then
		echo "-E Missing FILE_LIST argument" 1>&2
		USAGE;exit 1
	else
		FILE_LIST="$1"
		# ファイルリストのチェック
		if [ ! -f "${FILE_LIST}" ];then
			echo "-E FILE_LIST not a file -- \"${FILE_LIST}\"" 1>&2
			USAGE;exit 1
		fi
	fi
	;;
esac

# 変数定義(引数のチェック後)
case ${ACTION} in
import)
	FIL_IMPORT="1"
	;;
esac

# 作業開始前処理
PRE_PROCESS

#####################
# メインループ 開始 #
#####################

FILE_LIST_FIELD_SEARCH
FILE_LIST_TMP_MAKE

case ${ACTION} in
import|install)
	# 処理継続確認
	file_count=0
	file_names=""
	while read line ; do
		file_name="$(echo "${line}" \
			| awk -F'\t' \
				-v FIELD_FILE_NAME="${TMP_FIELD_FILE_NAME}" \
			'{print $FIELD_FILE_NAME}')"
		if [ ! "${file_name}" = "" ];then
			file_count=`expr ${file_count} + 1`
			file_names="${file_names:+${file_names}
}${file_name}"
		fi
	done < "${FILE_LIST_TMP}"
	echo "-I The following ${file_count} files will be MARKED to ${ACTION}:"
	echo "${file_names}" | sed 's#^#     #'
	if [ ${file_count} -gt 0 ];then
		echo "-Q Continue?" 1>&2
		YESNO
		if [ $? -ne 0 ];then
			echo "-I Interrupted."
			# 作業終了後処理
			POST_PROCESS;exit 0
		fi
	else
		# 作業終了後処理
		POST_PROCESS;exit 0
	fi
	;;
esac

case ${ACTION} in
import|install)
	# 選択ファイルのインポート・インストール
	awk -F '\t' \
		-v ACTION="${ACTION}" \
		-v SETUP_FIL_OPTIONS="${SETUP_FIL_OPTIONS}" \
		-v HOST_DIR="${HOST_DIR}" \
		-v HOSTNAME="${HOSTNAME}" \
		-v REMOTE_HOST="${REMOTE_HOST}" \
		-v USE_SSHFS="${USE_SSHFS}" \
		-v ROOT="${ROOT}" \
		-v FIELD_FILE_NAME="${TMP_FIELD_FILE_NAME}" \
		-v FIELD_MODE="${TMP_FIELD_MODE}" \
		-v FIELD_OWNER="${TMP_FIELD_OWNER}" \
		-v FIELD_GROUP="${TMP_FIELD_GROUP}" \
		-v FIELD_FIL_IMPORT_SRC="${TMP_FIELD_FIL_IMPORT_SRC}" \
	'BEGIN {
		if (USE_SSHFS == "yes") REMOTE_HOST=HOSTNAME
	}
	{
		# フィールド値の取得
		file_name=$FIELD_FILE_NAME
		mode=$FIELD_MODE
		owner=$FIELD_OWNER
		group=$FIELD_GROUP
		if (group !~/^$/) {
			owner=owner":"group
		}
		fil_import_src=$FIELD_FIL_IMPORT_SRC

		# コマンドラインの構成
		if (ACTION == "import") {
			cmd_line=sprintf("setup_fil.sh import")
			if (SETUP_FIL_OPTIONS !~/^$/) cmd_line=sprintf("%s %s"          ,cmd_line ,SETUP_FIL_OPTIONS)
			if (HOST_DIR          !~/^$/) cmd_line=sprintf("%s --hd \"%s\"" ,cmd_line ,HOST_DIR)
			if (ROOT              !~/^$/) cmd_line=sprintf("%s -r \"%s\""   ,cmd_line ,ROOT)
			if (REMOTE_HOST       !~/^$/) cmd_line=sprintf("%s -H \"%s\""   ,cmd_line ,REMOTE_HOST)
			                              cmd_line=sprintf("%s \"%s\""      ,cmd_line ,file_name)
			if (fil_import_src    !~/^$/) cmd_line=sprintf("%s -s \"%s\""   ,cmd_line ,fil_import_src)
		} else if (ACTION == "install") {
			cmd_line=sprintf("setup_fil.sh install")
			if (SETUP_FIL_OPTIONS !~/^$/) cmd_line=sprintf("%s %s"          ,cmd_line ,SETUP_FIL_OPTIONS)
			if (HOST_DIR          !~/^$/) cmd_line=sprintf("%s --hd \"%s\"" ,cmd_line ,HOST_DIR)
			if (ROOT              !~/^$/) cmd_line=sprintf("%s -r \"%s\""   ,cmd_line ,ROOT)
			if (REMOTE_HOST       !~/^$/) cmd_line=sprintf("%s -H \"%s\""   ,cmd_line ,REMOTE_HOST)
			                              cmd_line=sprintf("%s \"%s\""      ,cmd_line ,file_name)
			if (mode              !~/^$/) cmd_line=sprintf("%s -m %s"       ,cmd_line ,mode)
			if (owner             !~/^$/) cmd_line=sprintf("%s -o %s"       ,cmd_line ,owner)
		}

		# コマンドラインの出力・実行
		printf("+ %s\n", cmd_line)
		system(cmd_line)
	}' "${FILE_LIST_TMP}"
	if [ $? -ne 0 ];then
		POST_PROCESS;exit 1
	fi

	# 作業終了後処理
	POST_PROCESS;exit 0
	;;
esac

#####################
# メインループ 終了 #
#####################

