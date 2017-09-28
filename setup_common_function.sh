#!/bin/sh

# ==============================================================================
#   機能
#     setup_tools 用の共通関数定義ファイル
#   構文
#     . setup_common_function.sh
#
#   Copyright (c) 2011-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 関数定義
######################################################################
CMD()        { CMD_MAIN CMD        "$@"; }
CMD_V()      { CMD_MAIN CMD_V      "$@"; }
CMD_HOST()   { CMD_MAIN CMD_HOST   "$@"; }
CMD_HOST_V() { CMD_MAIN CMD_HOST_V "$@"; }

SSH()        { CMD_MAIN SSH        "$@"; }
SSH_V()      { CMD_MAIN SSH_V      "$@"; }
SSH_HOST()   { CMD_MAIN SSH_HOST   "$@"; }
SSH_HOST_V() { CMD_MAIN SSH_HOST_V "$@"; }

SCP_V()      { SCP_MAIN SCP_V      "$@"; }
SCP_HOST_V() { SCP_MAIN SCP_HOST_V "$@"; }

CMD_MAIN() {
	sub_name="$1" ; shift 1

	case ${sub_name} in
	CMD_HOST*)	host="$1" ; shift 1;;
	SSH*)	host="$1" ; shift 1;;
	esac

	case ${sub_name} in
	*_V)
		case ${VERBOSITY} in
		0)	cmd_line="$1";;
		1)	cmd_line="echo '+ $1'; $1";;
		esac
		;;
	*)
		cmd_line="$1"
		;;
	esac

	RESULT=0
	case ${sub_name} in
	CMD_HOST*)
		output="$(eval "${cmd_line} 2>&1")"
		;;
	SSH_HOST*)
		output="$(ssh ${SSH_OPTIONS} ${host} "${cmd_line}" 2>&1)"
		;;
	CMD*)
		eval "${cmd_line}"
		;;
	SSH*)
		ssh ${SSH_OPTIONS} ${host} "${cmd_line}"
		;;
	esac
	if [ $? -ne 0 ];then
		RESULT=1
	fi

	case ${sub_name} in
	*_HOST*)
		if [ ! "${output}" = "" ];then
			echo "${output}" | sed "s/^/${host}: /"
		fi
		;;
	esac
	return ${RESULT}
}

SCP_MAIN() {
	sub_name="$1" ; shift 1

	case ${sub_name} in
	SCP_HOST*)	host="$1" ; shift 1;;
	esac

	src="$1"
	dest="$2"

	cmd_line="scp ${SCP_OPTIONS} -p '${src}' '${dest}'"

	case ${sub_name} in
	SCP_V)
		CMD_V "${cmd_line}"
		;;
	SCP_HOST_V)
		CMD_HOST_V ${host} "${cmd_line}"
		;;
	esac
}

INTERMEDIATE_DIRS() {
	for dir in "$@" ; do
		echo "${dir}" | awk '{
			intermediate_dir=""
			while($0 != "") {
				match($0,/^\/*[^\/]*/)
				intermediate_dir=intermediate_dir substr($0,RSTART,RLENGTH)
				$0=substr($0,RLENGTH+1)
				print intermediate_dir
			}
		}'
	done | sort | uniq
}

