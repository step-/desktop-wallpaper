# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_trap=$(($__loaded_trap +1)) && echo >&2 "trap.sh{$__loaded_trap}"

trap_with_arg () {
	local sig func="$1"; shift
	for sig; do trap "$func $sig" "$sig"; done
}

on_signal () { # $1-signal-name
	trap - HUP INT QUIT TERM ABRT 0
	local signal=$1 exit_action res=0 bg_mode bg_img
	((DEBUG)) && echo >&2 "$FUNCNAME:$LINENO ==== .stdout ====" && cat -n "$RUNTIME_DIR/.stdout" >&2
	get_var_value_from_file "$RUNTIME_DIR/.stdout" EXIT exit_action
	((DEBUG)) && dprint_varname "$FUNCNAME:$LINENO" signal exit_action >&2

	# When $exit_action == "delete_event" we come here directly from the
	# gtkdialog-fired XML event "delete-event"¹ without passing through
	# dialog_exit_hook. For other values of $exit_action we come
	# through dialog_exit_hook.
	# ____
	# ¹ because on delete-event gtkdialog stops processing other signals
	# and exits. on_signal is invoked by XML action/function
	# "exit:delete_event_is_handled_by_on_signal".

	# XML signal "delete-event" - main window closed by [x]
	if [[ "$exit_action" == "delete_event"* ]]; then
		((DEBUG>1)) && dprint_varname "$FUNCNAME:$LINENO "$'\e[7mnon-blocking\e[0m' exit_action >&2

		# You can display an exit dialog but it has to be backgrounded
		# with & otherwise openbox WM, on detecting that the main window
		# is still open, will prompt to kill the main window. E.g.
		if : condition; then
			: dialog_ok_cancel ... & # non-blocking
			: do something ... & # also non-blocking
			: sleep 1 # keep!
		fi

	elif [[ "$exit_action" == "hook"* || "$signal" == "INT" ]]; then
		((DEBUG>1)) && dprint_varname "$FUNCNAME:$LINENO "$'\e[7mcan block\e[0m' exit_action >&2

		# Do whatever you want on your way out...
	fi

	## Surgically remove temp files: give some thought about which files can
	# go because the slideshow might keep running after this exit.
	if ((${#MAIN_DIALOG})); then
		# .screen_dims by AppRun
		# screen_bg*.p[bgp]m by reshape_image_with_method
		# everthing else by sh/gui.sh
		rm -f "$RUNTIME_DIR/.screen_dims" \
			"$RUNTIME_DIR/.screen_bg"*".p"[bgp]"m" \
			"$RUNTIME_DIR/."{func.sh,stdout} \
			"$RUNTIME_DIR/."{staged_change,last_commit,restore_point,undo} \
			"$RUNTIME_DIR/.gtk"* \
			"$RUNTIME_DIR/.ln_"* \
			"$MAIN_DIALOG_SENSITIVE" "$MAIN_DIALOG_EXIT" \
			;
		rm -fr "$WALLPAPER_SYNC_CONFIG" \
			;

		[ "true" = "$PERSIST_SELF_STATE" ] && push_apprun_wallpaper_state
		clear_apprun_wallpaper_state # volatile
	fi

	declare -F stop_stderr_filter_coprocess > /dev/null &&
		stop_stderr_filter_coprocess

	exit $res
}

get_var_value_from_file () { # $1-file $2-var_name $2-varname_var_value
	local file="$1" var_name="$2"
	local -n varname_var_value="$3"; varname_var_value=
	varname_var_value="$(awk -F'"' "/^$var_name"'="([^"]*)"/ {print $2; exit}' "$file")"
}

