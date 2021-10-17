# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_debug=$(($__loaded_debug +1)) && echo >&2 "debug.sh{$__loaded_debug}"

# ---------------------------------------------------------------------------- #
# REMINDER: unless you have a reason not to, redirect dprint* calls to stderr!
# ---------------------------------------------------------------------------- #

declare -i DEBUG

# Six dprint functions; usage:
#   init:   export DEBUG_WITH_BASENAME="_basename" # or ="" your choice
#   call:   dprint${DEBUG_WITH_BASENAME}{,_varname,_args} <parameters>

dprint () { # $1-lbl $2@-path...
# print "$1" "'"$2"'"...
	local __________="$-"; set +x
	echo -n "$1"; shift
	printf " '%s'" "$@"
	echo
	[[ "$__________" == *x* ]] && set -x
	:
}

dprint_basename () { # $1-lbl $2@-path...
# print "$1" "'"basename($2)"'"...
	local __________="$-"; set +x
	echo -n "$1"; shift
	local -a v=("$@"); v=("${v[@]/#/\/}"); v=("${v[@]//*\//}")
	printf " '%s'" "${v[@]}"
	echo
	[[ "$__________" == *x* ]] && set -x
	:
}

dprint_varname () { # $1-lbl $2@-varname...
# print "$1" "$2("value($2)")"...
	local __________="$-"; set +x
	echo -n "$1"; shift
	local -a k=($*)
	local -a e; printf -v e " \"$%s\"" $*; eval set -- ${e[*]}
	local -a v=("$@")
	for (( i = 0; i < ${#k[*]}; i++ )); do
		printf " %s(%s)" "${k[i]}" "${v[i]}"
	done
	echo
	[[ "$__________" == *x* ]] && set -x
	:
}

dprint_basename_varname () { # $1-lbl $2@-varname...
# print "$1" "$2("basename(value($2))")"...
	local __________="$-"; set +x
	echo -n "$1"; shift
	local -a k=($*)
	local -a e; printf -v e " \"$%s\"" $*; eval set -- ${e[*]}
	local -a v=("$@"); v=("${v[@]/#/\/}"); v=("${v[@]//*\//}")
	for (( i = 0; i < ${#k[*]}; i++ )); do
		printf " %s(%s)" "${k[i]}" "${v[i]}"
	done
	echo
	[[ "$__________" == *x* ]] && set -x
}

dprint_args () { # $1-pid
	local __________="$-"; set +x
	local -a a
	mapfile -d '' a < "/proc/$1/cmdline"
	dprint $'\033[7m'"pid=$1"$'\033[0m' "${a[@]}"
	[[ "$__________" == *x* ]] && set -x
	:
}

dprint_basename_args () { # $1-pid
	local __________="$-"; set +x
	local -a a
	mapfile -d '' a < "/proc/$1/cmdline"
	dprint_basename $'\033[7m'"pid=$1"$'\033[0m' "${a[@]}"
	[[ "$__________" == *x* ]] && set -x
	:
}

