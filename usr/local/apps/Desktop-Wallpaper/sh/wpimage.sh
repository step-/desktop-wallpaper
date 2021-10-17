# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_wpimage=$(($__loaded_wpimage +1)) && echo >&2 "wpimage.sh{$__loaded_wpimage}"

#######################################################################
#                            WPIMAGE SUPPORT                          #
#######################################################################

# A wpimage is a desktop wallpaper and lives in Z-folder <sub>=".wp".
# It can be reshaped before impression, in which case the reshaped image
# becomes the desktop wallpaper in <sub>=.NNN (aspect ratio).
# Wpimage files are cached for performance reasons.

get_wpimage_new () { # [-p] $1-in_img $2-varname_wpimage
# Return the cached path of a pixmap file corresponding to the input image $1.
# $1 can be an origin image file or a cached file.
# If the output image file doesn't exist it is created by calling an
# appropriate EXT_to_pixbuf function.
# Option -p: mkdir -p "${2%/*}"

	local opt_p; [ "$1" = "-p" ] && opt_p=1 && shift
	local in_img="$1"
	local -n varname_wpimage="$2"; varname_wpimage=
	local wpimage_out img_origin

	# see {N7} in sh/cache.sh
	has_cached_path "$in_img" &&
		get_cached_origin "$in_img" img_origin &&
		[ -s "$img_origin" ] &&
		in_img="$img_origin"

	get_cached_path_new "$in_img" ".wp" "" wpimage_out &&
		if ((opt_p)); then mkdir -p "${wpimage_out%/*}"; fi ||
	# -----------------------------------------------------------------
		return $?
	# -----------------------------------------------------------------

	# if an up-to-date wpimage doesn't exist
	if [ "$in_img" -nt "$wpimage_out" ]; then

		call_image_func "$in_img" to_pixmap "$in_img" "$wpimage_out"
		[ -s "$wpimage_out" ] &&
			varname_wpimage="$wpimage_out"
	else
		varname_wpimage="$wpimage_out"
	fi
}

