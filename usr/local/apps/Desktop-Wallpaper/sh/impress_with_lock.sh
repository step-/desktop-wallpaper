# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_impress_with_lock=$(($__loaded_impress_with_lock +1)) && echo >&2 "impress_with_lock.sh{$__loaded_impress_with_lock}"

wait_until_in_progress_impression_is_done () {
	((DEBUG>1)) && dprint "$FUNCNAME" "calling impress_wallpaper_with_lock" >&2
	impress_wallpaper_with_lock
}

impress_wallpaper_with_lock () { # $@-impress_wallpaper_arguments
# Call function impress_wallpaper under an exclusive blocking lock; update undo stack.
# Call this function with no argument to simply wait until the lock is released.
# The lock file is "$APPDIR" so as to block any other instance running as any user
# from touching the screen backdrop ($PINBOARD_FILE currently).

	((DEBUG>1)) && dprint "$FUNCNAME" "$@" >&2
	local err=0 bg_mode bg_img bg_img_origin
	{
		# Wait up to 5 seconds to acquire the lock.  Failure implies a programming error.
		flock -w 5 14 ||
			echo >&2 "${BASH_SOURCE##*/}:$LINENO: $i18n_error_breaking_loc (ELOCK) (14)"

		if (($#)); then
			impress_wallpaper "$@"; err=$?

			# update undo stack unless the cli or the slideshow set this wallpaper
			if (( ! err )) && (( ${#MAIN_DIALOG} )) && [[ -z "$WALLSLIDE_IMPRESSIONS" ]]; then
				get_apprun_wallpaper_state bg_mode bg_img bg_img_origin &&
					stack_push undo "$bg_mode:${bg_img_origin:-$bg_img}"
			fi
		fi

	} 14< "$(realpath "$APPDIR")"; exec 14<&-
	return $err
}

undo_wallpaper_with_lock () {
# set the previous wallpaper (TOS is the current wallpaper)

	local tos bg_mode bg_img bg_img_origin
	if ! stack_pop undo tos 2; then
		# ignore "short stack" errors and back-fill from restore point
		get_restore_point bg_mode bg_img bg_img_origin
		[ -s "$bg_img_origin" ] &&
			tos="$bg_mode:$bg_img_origin" ||
			tos="$bg_mode:$bg_img"
	fi
	((DEBUG>1)) && dprint_varname "$FUNCNAME:$LINENO" tos >&2
	impress_wallpaper_with_lock "$tos"
}

