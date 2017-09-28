#!/bin/sh

# ==============================================================================
#   機能
#     ファイルの操作を実行する
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

HOST_DIR_ORIG_PARENT="${HOME}/files"
HOST_DIR_ORIG_SUFFIX=".orig"
HOST_DIR_PARENTS="${HOME}/files"
HOST_DIR_SUFFIX=""

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
ROOT=""									#初期状態が「空文字」でなければならない変数
REMOTE_HOSTS="${HOSTNAME}"
IMPORT_SRC_FILE=""						#初期状態が「空文字」でなければならない変数
IMPORT_SRC_FILE_BASE=""					#初期状態が「空文字」でなければならない変数
DECOMP_MODE="none"
DECOMP_CMD=""							#初期状態が「空文字」でなければならない変数
DECOMP_IMPORT_SRC_FILE_BASE=""			#初期状態が「空文字」でなければならない変数
MODE=""									#初期状態が「空文字」でなければならない変数
OWNER=""								#初期状態が「空文字」でなければならない変数
OWNER_GROUP_NUMERIC_ID=""				#初期状態が「空文字」でなければならない変数
VERBOSITY="1"
DIFF_MODE="before"
DIFF_OPTIONS="-u"
PERM_CHECK_MODE="before"
OVERWRITE_PROMPT="ask"
IMPORT_MODE=""							#初期状態が「空文字」でなければならない変数
IMPORT_OWNER=""							#初期状態が「空文字」でなければならない変数
DIFF_DIR_ORIG_PARENT=""					#初期状態が「空文字」でなければならない変数
DIFF_DIR_ORIG_SUFFIX="${HOST_DIR_ORIG_SUFFIX}"
DIFF_DIR_PARENT=""						#初期状態が「空文字」でなければならない変数
DIFF_DIR_SUFFIX="${HOST_DIR_SUFFIX}"
DIFF_FILE_SUFFIX=".diff"
DIFF_OVERWRITE_PROMPT="ask"
DIFF_OWNER=""							#初期状態が「空文字」でなければならない変数
PAUSE_PER_REMOTE_HOST="no"
PAUSE_PER_DEST_FILE="no"

CONFIG_FILE="${HOME}/.setup_fil.conf"
# # 変数定義ファイルの読み込み
# if [ -f "${CONFIG_FILE}" ];then
# 	. "${CONFIG_FILE}"
# fi

remote_host=""							#初期状態が「空文字」でなければならない変数

#DEBUG=TRUE
TMP_DIR="/tmp"
SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}.${PID}"

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	:
}

POST_PROCESS() {
	# 一時ディレクトリの削除
	TMP_DIR_DEL
}

USAGE() {
	if [ "$1" = "" ];then
		cat <<- EOF 1>&2
			Usage:
			    setup_fil.sh {import|install} [OPTIONS ...] [ARGUMENTS ...]
		EOF
	elif [ "$1" = "import" ];then
		cat <<- EOF 1>&2
			Usage:
			    setup_fil.sh import [OPTIONS ...] DEST_FILE...
			
			ARGUMENTS:
			    DEST_FILE : Specify destination file(full-path).
			
			OPTIONS:
			    --ssh-options="SSH_OPTIONS ..."
			       Specify options which execute ssh command with.
			       See also ssh(1) for the further information on each option.
			    --scp-options="SCP_OPTIONS ..."
			       Specify options which execute scp command with.
			       See also scp(1) for the further information on each option.
			    --hdop=HOST_DIR_ORIG_PARENT
			       Specify parent directory of original host directory.
			    --hdos=HOST_DIR_ORIG_SUFFIX
			       Specify suffix of original host directory.
			    --hd=HOST_DIR
			       Specify host directory if it differs from the remote host name.
			    -C CONFIG_FILE
			       Specify a config file.
			    -r ROOT
			       Specify a DEST_FILE root directory.
			    -H "REMOTE_HOSTS ..."
			       Specify remote host name.
			    -s IMPORT_SRC_FILE
			       Specify import source file(full-path) if it differs from the destination file.
			    --decomp={none|before}
			    --decomp-cmd="DECOMP_CMD"
			       o If DECOMP_CMD is empty string, source file is decompressed by
			         automatically-selected decompress command before importing.
			         Following compressed file types are supported now in automatic
			         selection of a decompress command.
			           *.gz
			           *.bz2
			       o If DECOMP_CMD is non-empty string, source file is decompressed by
			         DECOMP_CMD command before importing.
			         DECOMP_CMD command must be able to decompress a file specified as the
			         1st argument whose name is "filename.extension" and must be able to
			         replace it by a file whose name is "filename".
			    -v {0|1}
			       Specify output verbosity.
			    --diff={none|before}
			    --diff-options="DIFF_OPTIONS ..."
			    --overwrite-prompt={ask|yes|no}
			    --import-mode=MODE
			    --import-owner=OWNER[:GROUP]
			    --diff-dir-orig-parent=DIFF_DIR_ORIG_PARENT
			    --diff-dir-orig-suffix=DIFF_DIR_ORIG_SUFFIX
			    --diff-file-suffix=DIFF_FILE_SUFFIX
			    --diff-overwrite-prompt={ask|yes|no}
			    --diff-owner=OWNER[:GROUP]
			    --pause-per-remote-host={yes|no}
			    --pause-per-dest-file={yes|no}
			    --help
			       Display this help and exit.
		EOF
		#	         DECOMP_CMD command must be able to decompress a file specified as the
		#	         1st argument and must be able to output it to standard output.
	elif [ "$1" = "install" ];then
		cat <<- EOF 1>&2
			Usage:
			    setup_fil.sh install [OPTIONS ...] DEST_FILE...
			
			ARGUMENTS:
			    DEST_FILE : Specify destination file(full-path).
			
			OPTIONS:
			    --ssh-options="SSH_OPTIONS ..."
			       Specify options which execute ssh command with.
			       See also ssh(1) for the further information on each option.
			    --scp-options="SCP_OPTIONS ..."
			       Specify options which execute scp command with.
			       See also scp(1) for the further information on each option.
			    --hdp="HOST_DIR_PARENTS ..."
			       Specify parent directory of host directory.
			    --hds=HOST_DIR_SUFFIX
			       Specify suffix of host directory.
			    --hd=HOST_DIR
			       Specify host directory if it differs from the remote host name.
			    -C CONFIG_FILE
			       Specify a config file.
			    -r ROOT
			       Specify a DEST_FILE root directory.
			    -H "REMOTE_HOSTS ..."
			       Specify remote host name.
			    -m MODE
			       Specify mode of DEST_FILE.
			    -o OWNER[:GROUP]
			       Specify owner and/or group of DEST_FILE.
			    -n
			       Specify if OWNER is numeric ID and/or GROUP is numeric ID.
			    -v {0|1}
			       Specify output verbosity.
			    --diff={none|before}
			    --diff-options="DIFF_OPTIONS ..."
			    --perm-check={none|before}
			    --overwrite-prompt={ask|yes|no}
			    --diff-dir-parent=DIFF_DIR_PARENT
			    --diff-dir-suffix=DIFF_DIR_SUFFIX
			    --diff-file-suffix=DIFF_FILE_SUFFIX
			    --diff-overwrite-prompt={ask|yes|no}
			    --diff-owner=OWNER[:GROUP]
			    --pause-per-remote-host={yes|no}
			    --pause-per-dest-file={yes|no}
			    --help
			       Display this help and exit.
		EOF
	fi
}

. yesno_function.sh

. setup_common_function.sh

# 変数定義
VAR_INIT() {
	if [ "${HOST_DIR}" = "" ];then
		host_dir_int="${remote_host}"
	else
		host_dir_int="${HOST_DIR}"
	fi
	dir="`dirname \"${arg}\"`"
	file="`basename \"${arg}\"`"
	case ${ACTION} in
	import)
		if [ "${IMPORT_SRC_FILE}" = "" ];then
			if [ "${remote_host}" = "${HOSTNAME}" ];then
				src_file="${ROOT}${dir}/${file}"
			else
				src_file="${REMOTE_UNAME}@${remote_host}:${ROOT}${dir}/${file}"
			fi
		else
			if [ "${remote_host}" = "${HOSTNAME}" ];then
				src_file="${ROOT}${IMPORT_SRC_FILE}"
			else
				src_file="${REMOTE_UNAME}@${remote_host}:${ROOT}${IMPORT_SRC_FILE}"
			fi
		fi
		dest_dir_tmp="${SCRIPT_TMP_DIR}/${host_dir_int}${HOST_DIR_ORIG_SUFFIX}${dir}"
		dest_dir="${HOST_DIR_ORIG_PARENT}/${host_dir_int}${HOST_DIR_ORIG_SUFFIX}${dir}"
		dest_file="${HOST_DIR_ORIG_PARENT}/${host_dir_int}${HOST_DIR_ORIG_SUFFIX}${dir}/${file}"
		diff_dir_tmp="${SCRIPT_TMP_DIR}/${host_dir_int}${HOST_DIR_ORIG_SUFFIX}${dir}"
		if [ "${DIFF_DIR_ORIG_PARENT}" = "" ];then
			diff_dir=""
			diff_file=""
		else
			diff_dir="${DIFF_DIR_ORIG_PARENT}/${host_dir_int}${DIFF_DIR_ORIG_SUFFIX}${dir}"
			diff_file="${DIFF_DIR_ORIG_PARENT}/${host_dir_int}${DIFF_DIR_ORIG_SUFFIX}${dir}/${file}${DIFF_FILE_SUFFIX}"
		fi
		;;
	install)
		src_file=""
		for host_dir_parent in ${HOST_DIR_PARENTS} ; do
			if [ -f "${host_dir_parent}/${host_dir_int}${HOST_DIR_SUFFIX}${dir}/${file}" ];then
				src_file="${host_dir_parent}/${host_dir_int}${HOST_DIR_SUFFIX}${dir}/${file}"
				break
			fi
		done
		if [ "${src_file}" = "" ];then
			echo "-W \"${dir}/${file}\" file not exist, or not a file in \"${HOST_DIR_PARENTS}\", skipped" 1>&2
			# 宛先ファイル毎に一時停止
			PAUSE_PER_DEST_FILE
			return 1
		fi
		dest_dir_tmp="${SCRIPT_TMP_DIR}/${host_dir_int}${HOST_DIR_SUFFIX}${ROOT}${dir}"
		dest_dir="${ROOT}${dir}"
		dest_file="${ROOT}${dir}/${file}"
		diff_dir_tmp="${SCRIPT_TMP_DIR}/${host_dir_int}${HOST_DIR_SUFFIX}${ROOT}${dir}"
		if [ "${DIFF_DIR_PARENT}" = "" ];then
			diff_dir=""
			diff_file=""
		else
			diff_dir="${DIFF_DIR_PARENT}/${host_dir_int}${DIFF_DIR_SUFFIX}${ROOT}${dir}"
			diff_file="${DIFF_DIR_PARENT}/${host_dir_int}${DIFF_DIR_SUFFIX}${ROOT}${dir}/${file}${DIFF_FILE_SUFFIX}"
		fi
		;;
	esac
}

# 一時ディレクトリの作成
TMP_DIR_MAKE() {
	cmd_line="mkdir -m 0700 -p '${dest_dir_tmp}'"
	CMD_HOST ${remote_host} "${cmd_line}"
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
	case ${ACTION} in
	install)
		if [ ! "${remote_host}" = "${HOSTNAME}" ];then
			SSH_HOST ${remote_host} "${cmd_line}"
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				POST_PROCESS;exit 1
			fi
		fi
		;;
	esac
}

# 一時ディレクトリの削除
TMP_DIR_DEL() {
	if [ ! ${DEBUG} ];then
		if [ ! "${remote_host}" = "" ];then
			cmd_line="rm -fr '${SCRIPT_TMP_DIR}'"
			CMD_HOST ${remote_host} "${cmd_line}"
			case ${ACTION} in
			install)
				if [ ! "${remote_host}" = "${HOSTNAME}" ];then
					SSH_HOST ${remote_host} "${cmd_line}"
				fi
				;;
			esac
		fi
	fi
}

# コピー元ファイルを一時ディレクトリにコピー
SRC_FILE_COPY_TO_TMP_DIR() {
	case ${ACTION} in
	import)
		if [ "${IMPORT_SRC_FILE}" = "" ];then
			if [ "${remote_host}" = "${HOSTNAME}" ];then
				CMD_HOST_V ${remote_host} "cp -pf '${src_file}' '${dest_dir_tmp}/${file}'"
			else
				SCP_HOST_V ${remote_host} "${src_file}" "${dest_dir_tmp}/${file}"
			fi
			if [ $? -ne 0 ];then
				echo "-W Command has ended unsuccessfully, skipped" 1>&2
				# 一時ディレクトリの削除
				TMP_DIR_DEL
				# 宛先ファイル毎に一時停止
				PAUSE_PER_DEST_FILE
				return 1
			fi
		else
			if [ "${remote_host}" = "${HOSTNAME}" ];then
				CMD_HOST_V ${remote_host} "cp -pf '${src_file}' '${dest_dir_tmp}/${IMPORT_SRC_FILE_BASE}'"
			else
				SCP_HOST_V ${remote_host} "${src_file}" "${dest_dir_tmp}/${IMPORT_SRC_FILE_BASE}"
			fi
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				POST_PROCESS;exit 1
			fi
			if [ ! "${DECOMP_CMD}" = "" ];then
				CMD_HOST_V ${remote_host} "${DECOMP_CMD} '${dest_dir_tmp}/${IMPORT_SRC_FILE_BASE}'"
				if [ $? -ne 0 ];then
					echo "-E Command has ended unsuccessfully." 1>&2
					POST_PROCESS;exit 1
				fi
				if [ ! "${DECOMP_IMPORT_SRC_FILE_BASE}" = "${file}" ];then
					CMD_HOST_V ${remote_host} "mv '${dest_dir_tmp}/${DECOMP_IMPORT_SRC_FILE_BASE}' '${dest_dir_tmp}/${file}'"
					if [ $? -ne 0 ];then
						echo "-E Command has ended unsuccessfully." 1>&2
						POST_PROCESS;exit 1
					fi
				fi
			else
				if [ ! "${IMPORT_SRC_FILE_BASE}" = "${file}" ];then
					CMD_HOST_V ${remote_host} "mv '${dest_dir_tmp}/${IMPORT_SRC_FILE_BASE}' '${dest_dir_tmp}/${file}'"
					if [ $? -ne 0 ];then
						echo "-E Command has ended unsuccessfully." 1>&2
						POST_PROCESS;exit 1
					fi
				fi
			fi
		fi
		;;
	install)
		if [ "${remote_host}" = "${HOSTNAME}" ];then
			CMD_HOST_V ${remote_host} "cp -pf '${src_file}' '${dest_dir_tmp}/${file}'"
		else
			SCP_HOST_V ${remote_host} "${src_file}" "${REMOTE_UNAME}@${remote_host}:${dest_dir_tmp}/${file}"
		fi
		if [ $? -ne 0 ];then
			echo "-W Command has ended unsuccessfully, skipped" 1>&2
			# 一時ディレクトリの削除
			TMP_DIR_DEL
			# 宛先ファイル毎に一時停止
			PAUSE_PER_DEST_FILE
			return 1
		fi
		;;
	esac
}

# コピー先一時ファイルのモード設定・オーナ・グループ設定
DEST_FILE_TMP_PERM_SET() {
	case ${ACTION} in
	import)
		if [ ! "${IMPORT_OWNER}" = "" ];then
			cmd_line="chown ${IMPORT_OWNER} '${dest_dir_tmp}/${file}'"
			CMD_HOST_V ${remote_host} "${cmd_line}"
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				POST_PROCESS;exit 1
			fi
		fi
		if [ ! "${IMPORT_MODE}" = "" ];then
			cmd_line="chmod ${IMPORT_MODE} '${dest_dir_tmp}/${file}'"
			CMD_HOST_V ${remote_host} "${cmd_line}"
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				POST_PROCESS;exit 1
			fi
		fi
		;;
	install)
		if [ ! "${OWNER}" = "" ];then
			cmd_line="chown ${OWNER} '${dest_dir_tmp}/${file}'"
			if [ "${remote_host}" = "${HOSTNAME}" ];then
				CMD_HOST_V ${remote_host} "${cmd_line}"
			else
				SSH_HOST_V ${remote_host} "${cmd_line}"
			fi
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				POST_PROCESS;exit 1
			fi
		fi
		if [ ! "${MODE}" = "" ];then
			cmd_line="chmod ${MODE} '${dest_dir_tmp}/${file}'"
			if [ "${remote_host}" = "${HOSTNAME}" ];then
				CMD_HOST_V ${remote_host} "${cmd_line}"
			else
				SSH_HOST_V ${remote_host} "${cmd_line}"
			fi
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				POST_PROCESS;exit 1
			fi
		fi
		;;
	esac
}

# DIFF一時ファイルのモード設定・オーナ・グループ設定
DIFF_FILE_TMP_PERM_SET() {
	case ${ACTION} in
	import|install)
		if [ ! "${DIFF_OWNER}" = "" ];then
			cmd_line="chown ${DIFF_OWNER} '${diff_dir_tmp}/${file}${DIFF_FILE_SUFFIX}'"
			CMD_HOST_V ${remote_host} "${cmd_line}"
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				POST_PROCESS;exit 1
			fi
		fi
		;;
	esac
}

# コピー先一時ファイルのファイル情報取得
DEST_FILE_TMP_INFO_GET() {
	cmd_line="ls -ald${OWNER_GROUP_NUMERIC_ID:+n} '${dest_dir_tmp}/${file}'"
	case ${ACTION} in
	import)
		dest_file_tmp_ll="$(CMD_HOST ${remote_host} "${cmd_line}")"
		;;
	install)
		if [ "${remote_host}" = "${HOSTNAME}" ];then
			dest_file_tmp_ll="$(CMD_HOST ${remote_host} "${cmd_line}")"
		else
			dest_file_tmp_ll="$(SSH_HOST ${remote_host} "${cmd_line}")"
		fi
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# DIFF一時ファイルのファイル情報取得
DIFF_FILE_TMP_INFO_GET() {
	cmd_line="ls -ald '${diff_dir_tmp}/${file}${DIFF_FILE_SUFFIX}'"
	case ${ACTION} in
	import|install)
		diff_file_tmp_ll="$(CMD_HOST ${remote_host} "${cmd_line}")"
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# コピー先ファイルの存在チェック
DEST_FILE_EXIST_CHECK() {
	cmd_line="test -f '${dest_file}'"
	case ${ACTION} in
	import)
		CMD_HOST ${remote_host} "${cmd_line}"
		;;
	install)
		if [ "${remote_host}" = "${HOSTNAME}" ];then
			CMD_HOST ${remote_host} "${cmd_line}"
		else
			SSH_HOST ${remote_host} "${cmd_line}"
		fi
		;;
	esac
}

# DIFF一時ファイルの存在チェック
DIFF_FILE_TMP_EXIST_CHECK() {
	cmd_line="test -f '${diff_dir_tmp}/${file}${DIFF_FILE_SUFFIX}'"
	case ${ACTION} in
	import|install)
		CMD_HOST ${remote_host} "${cmd_line}"
		;;
	esac
}

# DIFFファイルの存在チェック
DIFF_FILE_EXIST_CHECK() {
	cmd_line="test -f '${diff_file}'"
	case ${ACTION} in
	import|install)
		CMD_HOST ${remote_host} "${cmd_line}"
		;;
	esac
}

# コピー先ファイルのファイル情報取得 (コピー前)
DEST_FILE_INFO_GET_BEFORE() {
	cmd_line="ls -ald${OWNER_GROUP_NUMERIC_ID:+n} '${dest_file}'"
	case ${ACTION} in
	import)
		dest_file_ll="$(CMD_HOST ${remote_host} "${cmd_line}")"
		;;
	install)
		if [ "${remote_host}" = "${HOSTNAME}" ];then
			dest_file_ll="$(CMD_HOST ${remote_host} "${cmd_line}")"
		else
			dest_file_ll="$(SSH_HOST ${remote_host} "${cmd_line}")"
		fi
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# DIFFファイルのファイル情報取得 (コピー前)
DIFF_FILE_INFO_GET_BEFORE() {
	cmd_line="ls -ald '${diff_file}'"
	case ${ACTION} in
	import|install)
		diff_file_ll="$(CMD_HOST ${remote_host} "${cmd_line}")"
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# コピー先ファイルの内容チェック
DEST_FILE_CONTENT_CHECK() {
	if [ "${DIFF_MODE}" = "before" ];then
		cmd_line="diff ${DIFF_OPTIONS} '${dest_file}' '${dest_dir_tmp}/${file}'"
		case ${ACTION} in
		import)
			CMD "${cmd_line}" > "${diff_dir_tmp}/${file}${DIFF_FILE_SUFFIX}" 2>&1
			;;
		install)
			if [ "${remote_host}" = "${HOSTNAME}" ];then
				CMD "${cmd_line}" > "${diff_dir_tmp}/${file}${DIFF_FILE_SUFFIX}" 2>&1
			else
				SSH ${remote_host} "${cmd_line}" > "${diff_dir_tmp}/${file}${DIFF_FILE_SUFFIX}" 2>&1
			fi
			;;
		esac
		DIFF_RC=$?
		echo "-I DIFF START"
		cmd_line="cat '${diff_dir_tmp}/${file}${DIFF_FILE_SUFFIX}'"
		CMD_HOST ${remote_host} "${cmd_line}"
		echo "-I DIFF END"
		if [ ${DIFF_RC} -eq 2 ];then
			echo "-E Command has ended unsuccessfully." 1>&2
			POST_PROCESS;exit 1
		fi
	fi
}

# コピー先ファイルのパーミッションチェック
DEST_FILE_PERM_CHECK() {
	if [ "${PERM_CHECK_MODE}" = "before" ];then
		case ${ACTION} in
		install)
			dest_file_tmp_perm="$(echo "${dest_file_tmp_ll}" | awk '{printf("%s\t%s\t%s",$2,$4,$5)}')"
			dest_file_perm="$(echo "${dest_file_ll}" | awk '{printf("%s\t%s\t%s",$2,$4,$5)}')"
			test "${dest_file_tmp_perm}" = "${dest_file_perm}"
			PERM_CHECK_RC=$?
			;;
		esac
	fi
}

# コピー先ファイルの上書き確認
DEST_FILE_OVERWRITE_PROMPT() {
	echo "-I Following file exist in the ${ACTION} destination directory"
	echo "Dest: ${dest_file_ll}"
	echo "Src : ${dest_file_tmp_ll}"
	if [ ! "${DIFF_MODE}" = "none" ];then
		if [ ${DIFF_RC} -eq 0 ];then
			echo "-I Content    : identical"
		elif [ ${DIFF_RC} -eq 1 ];then
			echo "-W Content    : differ (See above)" 1>&2
		fi
	fi
	case ${ACTION} in
	install)
		if [ ! "${PERM_CHECK_MODE}" = "none" ];then
			if [ ${PERM_CHECK_RC} -eq 0 ];then
				echo "-I Permission : identical"
			else
				echo "-W Permission : differ (See above)" 1>&2
			fi
		fi
		;;
	esac
	case ${OVERWRITE_PROMPT} in
	ask)
		echo "-Q Overwrite?" 1>&2
		YESNO
		OVERWRITE_PROMPT_RC=$?
		;;
	yes)	OVERWRITE_PROMPT_RC=0;;
	no)	OVERWRITE_PROMPT_RC=1;;
	esac
	if [ ${OVERWRITE_PROMPT_RC} -ne 0 ];then
		echo "-I Skipping..."
		# 一時ディレクトリの削除
		TMP_DIR_DEL
		# 宛先ファイル毎に一時停止
		PAUSE_PER_DEST_FILE
		return 1
	else
		echo "-I Overwriting..."
	fi
}

# DIFFファイルの上書き確認
DIFF_FILE_OVERWRITE_PROMPT() {
	echo "-I Following file exist in the ${ACTION} diff directory"
	echo "Dest: ${diff_file_ll}"
	echo "Src : ${diff_file_tmp_ll}"
	case ${DIFF_OVERWRITE_PROMPT} in
	ask)
		echo "-Q Overwrite?" 1>&2
		YESNO
		DIFF_OVERWRITE_PROMPT_RC=$?
		;;
	yes)	DIFF_OVERWRITE_PROMPT_RC=0;;
	no)	DIFF_OVERWRITE_PROMPT_RC=1;;
	esac
	if [ ${DIFF_OVERWRITE_PROMPT_RC} -ne 0 ];then
		echo "-I Skipping..."
		# 一時ディレクトリの削除
		TMP_DIR_DEL
		# 宛先ファイル毎に一時停止
		PAUSE_PER_DEST_FILE
		return 1
	else
		echo "-I Overwriting..."
	fi
}

# コピー先ディレクトリの作成
DEST_DIR_MAKE() {
	case ${ACTION} in
	import)
		dest_dirs_intermediate="$(INTERMEDIATE_DIRS "${dest_dir}")"
		for dest_dir_intermediate in ${dest_dirs_intermediate} ; do
			if [ ! -d "${dest_dir_intermediate}" ];then
				cmd_line="mkdir '${dest_dir_intermediate}'"
				CMD_HOST_V ${remote_host} "${cmd_line}"
				if [ $? -ne 0 ];then
					echo "-E Command has ended unsuccessfully." 1>&2
					POST_PROCESS;exit 1
				fi
				if [ ! "${IMPORT_OWNER}" = "" ];then
					cmd_line="chown ${IMPORT_OWNER} '${dest_dir_intermediate}'"
					CMD_HOST_V ${remote_host} "${cmd_line}"
					if [ $? -ne 0 ];then
						echo "-E Command has ended unsuccessfully." 1>&2
						POST_PROCESS;exit 1
					fi
				fi
				if [ ! "${IMPORT_MODE}" = "" ];then
					cmd_line="chmod ${IMPORT_MODE} '${dest_dir_intermediate}'"
					CMD_HOST_V ${remote_host} "${cmd_line}"
					if [ $? -ne 0 ];then
						echo "-E Command has ended unsuccessfully." 1>&2
						POST_PROCESS;exit 1
					fi
				fi
			fi
		done
		;;
	esac
}

# DIFFディレクトリの作成
DIFF_DIR_MAKE() {
	case ${ACTION} in
	import|install)
		diff_dirs_intermediate="$(INTERMEDIATE_DIRS "${diff_dir}")"
		for diff_dir_intermediate in ${diff_dirs_intermediate} ; do
			if [ ! -d "${diff_dir_intermediate}" ];then
				cmd_line="mkdir '${diff_dir_intermediate}'"
				CMD_HOST_V ${remote_host} "${cmd_line}"
				if [ $? -ne 0 ];then
					echo "-E Command has ended unsuccessfully." 1>&2
					POST_PROCESS;exit 1
				fi
				if [ ! "${DIFF_OWNER}" = "" ];then
					cmd_line="chown ${DIFF_OWNER} '${diff_dir_intermediate}'"
					CMD_HOST_V ${remote_host} "${cmd_line}"
					if [ $? -ne 0 ];then
						echo "-E Command has ended unsuccessfully." 1>&2
						POST_PROCESS;exit 1
					fi
				fi
			fi
		done
		;;
	esac
}

# コピー先一時ファイルをコピー先ファイルにコピー
DEST_FILE_TMP_COPY_TO_DEST_FILE() {
	cmd_line="cp -pf '${dest_dir_tmp}/${file}' '${dest_file}'"
	case ${ACTION} in
	import)
		CMD_HOST_V ${remote_host} "${cmd_line}"
		;;
	install)
		if [ "${remote_host}" = "${HOSTNAME}" ];then
			CMD_HOST_V ${remote_host} "${cmd_line}"
		else
			SSH_HOST_V ${remote_host} "${cmd_line}"
		fi
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# DIFF一時ファイルをDIFFファイルにコピー
DIFF_FILE_TMP_COPY_TO_DIFF_FILE() {
	cmd_line="cp -pf '${diff_dir_tmp}/${file}${DIFF_FILE_SUFFIX}' '${diff_file}'"
	case ${ACTION} in
	import|install)
		CMD_HOST_V ${remote_host} "${cmd_line}"
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# コピー先ファイルのファイル情報取得 (コピー後)
DEST_FILE_INFO_GET_AFTER() {
	cmd_line="ls -ald${OWNER_GROUP_NUMERIC_ID:+n} '${dest_file}'"
	case ${ACTION} in
	import)
		dest_file_ll="$(CMD_HOST ${remote_host} "${cmd_line}")"
		;;
	install)
		if [ "${remote_host}" = "${HOSTNAME}" ];then
			dest_file_ll="$(CMD_HOST ${remote_host} "${cmd_line}")"
		else
			dest_file_ll="$(SSH_HOST ${remote_host} "${cmd_line}")"
		fi
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# DIFFファイルのファイル情報取得 (コピー後)
DIFF_FILE_INFO_GET_AFTER() {
	cmd_line="ls -ald '${diff_file}'"
	case ${ACTION} in
	import|install)
		diff_file_ll="$(CMD_HOST ${remote_host} "${cmd_line}")"
		;;
	esac
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
}

# コピー先ファイルのファイル情報表示
DEST_FILE_INFO_SHOW() {
	echo "-I Following file is copied"
	echo "${dest_file_ll}"
}

# DIFFファイルのファイル情報表示
DIFF_FILE_INFO_SHOW() {
	echo "-I Following file is copied"
	echo "${diff_file_ll}"
}

# 宛先ファイル毎に一時停止
PAUSE_PER_DEST_FILE() {
	if [ "${PAUSE_PER_DEST_FILE}" = "yes" ];then
		pause.sh
	fi
}

# リモートホスト毎に一時停止
PAUSE_PER_REMOTE_HOST() {
	if [ "${PAUSE_PER_REMOTE_HOST}" = "yes" ];then
		pause.sh
	fi
}

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
CMD_ARG="`${GETOPT} -o C:r:H:s:m:o:nv: -l ssh-options:,scp-options:,hdop:,hdos:,hdp:,hds:,hd:,decomp:,decomp-cmd:,diff:,diff-options:,perm-check:,overwrite-prompt:,import-mode:,import-owner:,diff-dir-orig-parent:,diff-dir-orig-suffix:,diff-dir-parent:,diff-dir-suffix:,diff-file-suffix:,diff-overwrite-prompt:,diff-owner:,pause-per-remote-host:,pause-per-dest-file:,help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE ${ACTION};exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	--ssh-options)	SSH_OPTIONS="$2" ; shift 2;;
	--scp-options)	SCP_OPTIONS="$2" ; shift 2;;
	--hdop)	HOST_DIR_ORIG_PARENT="$2" ; shift 2;;
	--hdos)	HOST_DIR_ORIG_SUFFIX="$2" ; shift 2;;
	--hdp)	HOST_DIR_PARENTS="$2" ; shift 2;;
	--hds)	HOST_DIR_SUFFIX="$2" ; shift 2;;
	--hd)	HOST_DIR="$2" ; shift 2;;
	-C)
		CONFIG_FILE="$2" ; shift 2
		# 変数定義ファイルの読み込み
		if [ ! -f "${CONFIG_FILE}" ];then
			echo "-E CONFIG_FILE not a file -- \"${CONFIG_FILE}\"" 1>&2
			USAGE ${ACTION};exit 1
		else
			. "${CONFIG_FILE}"
		fi
		;;
	-r)	ROOT="`echo \"$2\" | sed 's#/$##'`" ; shift 2;;
	-H)	REMOTE_HOSTS="$2" ; shift 2;;
	-s)	IMPORT_SRC_FILE="$2" ; shift 2;;
	--decomp)
		case "$2" in
		none|before)	DECOMP_MODE="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--decomp-cmd)	DECOMP_CMD="$2" ; shift 2;;
	-m)	MODE="$2" ; shift 2;;
	-o)	OWNER="$2" ; shift 2;;
	-n)	OWNER_GROUP_NUMERIC_ID=TRUE ; shift 1;;
	-v)
		case "$2" in
		0|1)	VERBOSITY="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--diff)
		case "$2" in
		none|before)	DIFF_MODE="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--diff-options)	DIFF_OPTIONS="$2" ; shift 2;;
	--perm-check)
		case "$2" in
		none|before)	PERM_CHECK_MODE="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--overwrite-prompt)
		case "$2" in
		ask|yes|no)	OVERWRITE_PROMPT="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--import-mode)	IMPORT_MODE="$2" ; shift 2;;
	--import-owner)	IMPORT_OWNER="$2" ; shift 2;;
	--diff-dir-orig-parent)	DIFF_DIR_ORIG_PARENT="$2" ; shift 2;;
	--diff-dir-orig-suffix)	DIFF_DIR_ORIG_SUFFIX="$2" ; shift 2;;
	--diff-dir-parent)	DIFF_DIR_PARENT="$2" ; shift 2;;
	--diff-dir-suffix)	DIFF_DIR_SUFFIX="$2" ; shift 2;;
	--diff-file-suffix)	DIFF_FILE_SUFFIX="$2" ; shift 2;;
	--diff-overwrite-prompt)
		case "$2" in
		ask|yes|no)	DIFF_OVERWRITE_PROMPT="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--diff-owner)	DIFF_OWNER="$2" ; shift 2;;
	--pause-per-remote-host|--pause-per-dest-file)
		case "$2" in
		yes|no)
			case "${opt}" in
			--pause-per-remote-host)	PAUSE_PER_REMOTE_HOST="$2" ; shift 2;;
			--pause-per-dest-file)	PAUSE_PER_DEST_FILE="$2" ; shift 2;;
			esac
			;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	--help)
		USAGE ${ACTION};exit 0
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
		echo "-E Missing DEST_FILE argument" 1>&2
		USAGE ${ACTION};exit 1
	fi
	;;
esac

# 変数定義(引数のチェック後)
case ${ACTION} in
import)
	if [ ! "${IMPORT_SRC_FILE}" = "" ];then
		IMPORT_SRC_FILE_BASE="`basename \"${IMPORT_SRC_FILE}\"`"
	fi
	if [ ! "${DECOMP_MODE}" = "none" ];then
		if [ "${DECOMP_CMD}" = "" ];then
			case "${IMPORT_SRC_FILE_BASE}" in
			*.gz)
				DECOMP_CMD="gzip -d"
				DECOMP_IMPORT_SRC_FILE_BASE="`echo \"${IMPORT_SRC_FILE_BASE}\" | sed -e 's#\.gz$##'`"
				;;
			*.bz2)
				DECOMP_CMD="bzip2 -d"
				DECOMP_IMPORT_SRC_FILE_BASE="`echo \"${IMPORT_SRC_FILE_BASE}\" | sed -e 's#\.bz2$##'`"
				;;
			esac
		fi
		if [ \( ! "${DECOMP_CMD}" = "" \) -a \( "${DECOMP_IMPORT_SRC_FILE_BASE}" = "" \) ];then
			DECOMP_IMPORT_SRC_FILE_BASE="`echo \"${IMPORT_SRC_FILE_BASE}\" | sed -e 's#\.[^\.]\+$##'`"
		fi
	fi
	;;
esac

# # ホスト名親ディレクトリのチェック
# case ${ACTION} in
# import)
# 	if [ ! -d "${HOST_DIR_ORIG_PARENT}" ];then
# 		echo "-E HOST_DIR_ORIG_PARENT not a directory -- \"${HOST_DIR_ORIG_PARENT}\"" 1>&2
# 		USAGE ${ACTION};exit 1
# 	fi
# 	;;
# esac

# sshコマンドの実行チェック
for remote_host in ${REMOTE_HOSTS} ; do
	if [ ! "${remote_host}" = "${HOSTNAME}" ];then
		cmd_line="ssh ${SSH_OPTIONS:+${SSH_OPTIONS} }${remote_host} :"
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
done
remote_host=""

# 作業開始前処理
PRE_PROCESS

#####################
# メインループ 開始 #
#####################
for remote_host in ${REMOTE_HOSTS} ; do
	for arg in "$@" ; do
		# 画面に改行を出力
		echo

		VAR_INIT || continue

		TMP_DIR_MAKE
		SRC_FILE_COPY_TO_TMP_DIR || continue
		DEST_FILE_TMP_PERM_SET
		DEST_FILE_TMP_INFO_GET

		DEST_FILE_EXIST_CHECK
		if [ $? -eq 0 ];then
			DEST_FILE_INFO_GET_BEFORE
			DEST_FILE_CONTENT_CHECK
			DEST_FILE_PERM_CHECK
			DEST_FILE_OVERWRITE_PROMPT || continue
		fi
		DEST_DIR_MAKE
		DEST_FILE_TMP_COPY_TO_DEST_FILE
		DEST_FILE_INFO_GET_AFTER
		DEST_FILE_INFO_SHOW

		if [ \( ! "${diff_dir}" = "" \) -a \( ! "${diff_file}" = "" \) ];then
			DIFF_FILE_TMP_EXIST_CHECK
			if [ $? -eq 0 ];then
				DIFF_FILE_TMP_PERM_SET
				DIFF_FILE_TMP_INFO_GET
				DIFF_FILE_EXIST_CHECK
				if [ $? -eq 0 ];then
					DIFF_FILE_INFO_GET_BEFORE
					DIFF_FILE_OVERWRITE_PROMPT || continue
				fi
				DIFF_DIR_MAKE
				DIFF_FILE_TMP_COPY_TO_DIFF_FILE
				DIFF_FILE_INFO_GET_AFTER
				DIFF_FILE_INFO_SHOW
			fi
		fi

		# 一時ディレクトリの削除
		TMP_DIR_DEL

		# 宛先ファイル毎に一時停止
		PAUSE_PER_DEST_FILE
	done

	# リモートホスト毎に一時停止
	PAUSE_PER_REMOTE_HOST
done
remote_host=""
#####################
# メインループ 終了 #
#####################

# 作業終了後処理
POST_PROCESS;exit 0

