#!/bin/sh

# ==============================================================================
#   機能
#     パッケージリストに従ってパッケージの操作を実行する
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

SSH_OPTIONS="-l ${REMOTE_UNAME}"
SCP_OPTIONS=""

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
REMOTE_HOST="${HOSTNAME}"
PKG_SYSTEM=""							#初期状態が「空文字」でなければならない変数
PKG_GROUP=""							#初期状態が「空文字」でなければならない変数
HOST=""									#初期状態が「空文字」でなければならない変数
SETUP_MANUAL=""							#初期状態が「空文字」でなければならない変数
VERBOSITY="1"

CONFIG_FILE="${HOME}/.setup_pkg_list.conf"
# # 変数定義ファイルの読み込み
# if [ -f "${CONFIG_FILE}" ];then
# 	. "${CONFIG_FILE}"
# fi

#DEBUG=TRUE
TMP_DIR="/tmp"
SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}.${PID}"
PKG_LIST_TMP="${SCRIPT_TMP_DIR}/pkg_list.tmp"
PKG_SCRIPT_TMP="${SCRIPT_TMP_DIR}/pkg_script.tmp"

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	# 一時ディレクトリの作成
	cmd_line="mkdir -p '${SCRIPT_TMP_DIR}'"
	CMD "${cmd_line}"
	if [ ! "${REMOTE_HOST}" = "${HOSTNAME}" ];then
		SSH ${REMOTE_HOST} "${cmd_line}"
	fi
}

POST_PROCESS() {
	# 一時ディレクトリの削除
	if [ ! ${DEBUG} ];then
		cmd_line="rm -fr '${SCRIPT_TMP_DIR}'"
		CMD "${cmd_line}"
		if [ ! "${REMOTE_HOST}" = "${HOSTNAME}" ];then
			SSH ${REMOTE_HOST} "${cmd_line}"
		fi
	fi
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    setup_pkg_list.sh ACTION [OPTIONS ...] [ARGUMENTS ...]
		
		ACTIONS:
		    show [OPTIONS ...] PKG_LIST
		       Show packages.
		    install [OPTIONS ...] PKG_LIST
		       Install packages.
		
		ARGUMENTS:
		    PKG_LIST : Specify a package list.
		
		OPTIONS:
		    --ssh-options="SSH_OPTIONS ..."
		       Specify options which execute ssh command with.
		       See also ssh(1) for the further information on each option.
		       (Available with: show, install)
		    --scp-options="SCP_OPTIONS ..."
		       Specify options which execute scp command with.
		       See also scp(1) for the further information on each option.
		       (Available with: show, install)
		    -C CONFIG_FILE
		       Specify a config file.
		       (Available with: show, install)
		    -H REMOTE_HOST
		       Specify remote host name.
		       (Available with: show, install)
		    -P PKG_SYSTEM
		       PKG_SYSTEM : {apt|dnf}
		       Specify package system on target host.
		       (Available with: show, install)
		    -g PKG_GROUP
		       Specify package group field value in PKG_LIST.
		       (Available with: show, install)
		    -h HOST
		       Specify host field name in PKG_LIST.
		       (Available with: show, install)
		    -s SETUP_MANUAL
		       Specify setup manual field value in PKG_LIST.
		       (Available with: show, install)
		    -v {0|1}
		       Specify output verbosity.
		       (Available with: show, install)
		    --help
		       Display this help and exit.
	EOF
}

. yesno_function.sh

. setup_common_function.sh
. setup_pkg_list_function.sh

######################################################################
# メインルーチン
######################################################################

# ACTIONのチェック
if [ "$1" = "" ];then
	echo "-E Missing ACTION" 1>&2
	USAGE;exit 1
else
	case "$1" in
	show|install)
		action="$1"
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
CMD_ARG="`${GETOPT} -o C:H:P:g:h:s:v: -l ssh-options:,scp-options:,help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	--ssh-options)	SSH_OPTIONS="$2" ; shift 2;;
	--scp-options)	SCP_OPTIONS="$2" ; shift 2;;
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
	-P)	PKG_SYSTEM="$2" ; shift 2;;
	-g)	PKG_GROUP="$2" ; shift 2;;
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
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 引数のチェック
case ${action} in
show|install)
	# 第1引数のチェック
	if [ "$1" = "" ];then
		echo "-E Missing PKG_LIST argument" 1>&2
		USAGE;exit 1
	else
		PKG_LIST="$1"
		# パッケージリストのチェック
		if [ ! -f "${PKG_LIST}" ];then
			echo "-E PKG_LIST not a file -- \"${PKG_LIST}\"" 1>&2
			USAGE;exit 1
		fi
	fi
	;;
esac

# sshコマンドの実行チェック
if [ ! "${REMOTE_HOST}" = "${HOSTNAME}" ];then
	cmd_line="ssh ${SSH_OPTIONS:+${SSH_OPTIONS} }${REMOTE_HOST} :"
	output="$(${cmd_line} 2>&1)"
	if [ $? -ne 0 ];then
		echo "-E 'ssh' command execution check failed" 1>&2
		echo "     Command:" 1>&2
		echo "       ${cmd_line}" 1>&2
		echo "     Response:" 1>&2
		echo "${output}" | sed 's#^#       #' 1>&2
		exit 1	# USAGE表示なし
	fi
fi

# パッケージシステムのチェック
if [ "${PKG_SYSTEM}" = "" ];then
	output_uname_s=""
	cmd_line="uname -s"
	if [ "${REMOTE_HOST}" = "${HOSTNAME}" ];then
		output_uname_s="$(CMD "${cmd_line}")"
	else
		output_uname_s="$(SSH ${REMOTE_HOST} "${cmd_line}")"
	fi
	case ${output_uname_s} in
	Linux)
		output_check_linux=""
		cmd_line=". /etc/os-release 2>&1 && echo \"\${ID}\""
		if [ "${REMOTE_HOST}" = "${HOSTNAME}" ];then
			output_check_linux="$(CMD "${cmd_line}")"
		else
			output_check_linux="$(SSH ${REMOTE_HOST} "${cmd_line}")"
		fi
		case "${output_check_linux}" in
		debian)
			PKG_SYSTEM="apt"
			;;
		fedora)
			PKG_SYSTEM="dnf"
			;;
		esac
		;;
	esac
	if [ "${PKG_SYSTEM}" = "" ];then
		echo "-E Package system check failed"                  1>&2
		echo "     output_uname_s     : ${output_uname_s}"     1>&2
		echo "     output_check_linux : ${output_check_linux}" 1>&2
		exit 1	# USAGE表示なし
	fi
fi

# 作業開始前処理
PRE_PROCESS

#####################
# メインループ 開始 #
#####################

PKG_LIST_FIELD_SEARCH
PKG_LIST_TMP_MAKE

case ${action} in
install)
	# 処理継続確認
	pkg_count=0
	pkg_names=""
	while read line ; do
		pkg_name="$(echo "${line}" | awk '{print $1}')"
		if [ ! "${pkg_name}" = "" ];then
			pkg_count=`expr ${pkg_count} + 1`
			pkg_names="${pkg_names:+${pkg_names} }${pkg_name}"
		fi
	done < "${PKG_LIST_TMP}"
	echo "-I The following ${pkg_count} packages will be MARKED to ${action}:"
	echo "     ${pkg_names}"
	if [ ${pkg_count} -gt 0 ];then
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

case ${action} in
show|install)
	# 一時ファイルの作成
	case ${action} in
	show)
		PKG_SHOW_SCRIPT_TMP_MAKE
		;;
	install)
		PKG_INST_SCRIPT_TMP_MAKE
		;;
	esac

	# 一時ファイルを一時ディレクトリにコピー
	if [ ! "${REMOTE_HOST}" = "${HOSTNAME}" ];then
		SCP_V "${PKG_LIST_TMP}" "${REMOTE_UNAME}@${REMOTE_HOST}:${SCRIPT_TMP_DIR}"
		if [ $? -ne 0 ];then
			echo "-E Command has ended unsuccessfully." 1>&2
			POST_PROCESS;exit 1
		fi
		SCP_V "${PKG_SCRIPT_TMP}" "${REMOTE_UNAME}@${REMOTE_HOST}:${SCRIPT_TMP_DIR}"
		if [ $? -ne 0 ];then
			echo "-E Command has ended unsuccessfully." 1>&2
			POST_PROCESS;exit 1
		fi
	fi

	# パッケージの情報表示・インストール・削除
	cmd_line="${PKG_SCRIPT_TMP} ${PKG_LIST_TMP}"
	if [ "${REMOTE_HOST}" = "${HOSTNAME}" ];then
		CMD_V "${cmd_line}"
	else
		SSH_OPTIONS_SAVE=${SSH_OPTIONS}
		SSH_OPTIONS="${SSH_OPTIONS} -q -t"
		SSH_V ${REMOTE_HOST} "${cmd_line}"
		SSH_OPTIONS=${SSH_OPTIONS_SAVE}
		unset SSH_OPTIONS_SAVE
	fi
	case ${action} in
	show)
		RC=$?
		if [ ${RC} -ne 0 ];then
			case ${RC} in
			*)	echo "-E Command has ended unsuccessfully." 1>&2;;
			esac
			POST_PROCESS;exit 1
		fi
		;;
	install)
		RC=$?
		if [ ${RC} -ne 0 ];then
			case ${RC} in
			1)	echo "-I Interrupted.";;
			*)	echo "-E Command has ended unsuccessfully." 1>&2;;
			esac
			POST_PROCESS;exit 1
		fi
		;;
	esac

	# 作業終了後処理
	POST_PROCESS;exit 0
	;;
esac

#####################
# メインループ 終了 #
#####################

