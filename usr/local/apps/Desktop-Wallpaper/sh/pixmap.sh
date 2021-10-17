# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_pixmap=$(($__loaded_pixmap +1)) && echo >&2 "pixmap.sh{$__loaded_pixmap}"

#######################################################################
#                             PIXMAP SUPPORT                          #
#######################################################################

# get_pixmap_new creates the pixmap file that corresponds to the small image in
# the main window (gtkdialog PIXMAP variable). $PIXMAP_CURSOR links to the
# currently displayed file, which is a GtkImage compatible image file or itself
# a symbolic link to such an image file.

# $PIXMAP_CURSOR symlinks to the currently-displayed pixmap.
# $PIXMAP_CURSOR's file name extensions is ".png" regardless of the current
# pixmap's image format.  Extensions are transparent to GtkImage, which sniffs
# content to determine image format. The ".png" extension is a mere convenience
# to underline the image nature of $PIXMAP_CURSOR's target file.
declare -x -r PIXMAP_CURSOR="$RUNTIME_DIR/pixmap.png"

get_pixmap_new () { # [-p] $1-img_origin $2-varname_img_pixmap
# Return into $2 the cached path of a pixmap file corresponding to the input
# image $1.  Return "" into $2 on error.
# $1 is an origin image file _outside_ the cache.
# If the pixmap file doesn't exist it is created anew by calling an appropriate
# EXT_to_pixmap function and compositing its output with a $BG_color backdrop.
# Option -p: mkdir -p "${2%/*}"

	local opt_p; [ "$1" = "-p" ] && opt_p=1 && shift
	local img_origin="$1"
	local -n varname_img_pixmap="$2"; varname_img_pixmap=
	local pixmap_out pixmap_bg
	get_cached_path_new "$img_origin" ".pixmap" "" pixmap_out &&
		if ((opt_p)); then mkdir -p "${pixmap_out%/*}"; fi ||
	# -----------------------------------------------------------------
		return $?
	# -----------------------------------------------------------------

	# if an up-to-date pixmap_out doesn't exist
	if [ "$img_origin" -nt "$pixmap_out" ]; then

		# convert is_supported_image $img_origin to GtkImage $pixmap_out
		call_image_func "$img_origin" to_pixmap "$img_origin" "$pixmap_out"

		if [ -s "$pixmap_out" ]; then
			varname_img_pixmap="$pixmap_out"

			# center pixmap_out on color background
			pixmap_bg="$pixmap_out.bg.${pixmap_out##*.}"
			! [ -s "$pixmap_bg" ] &&
			case "$PREFERRED_IMAGE_FORMAT" in
			("WEBP") # optimized for speed
				WALLPAPER_CACHE_LEVEL=1 \
					optimized_reshape_webp_with_method "pixmap" "$pixmap_out" "$pixmap_bg" \
					"$IMAGE_PIXMAP_WIDTH" "$IMAGE_PIXMAP_HEIGHT" \
					"$IMAGE_PIXMAP_IMAGE_QUALITY"
				;;
			(*)
				WALLPAPER_CACHE_LEVEL=1 \
					reshape_image_with_method "pixmap" "$pixmap_out" "$pixmap_bg" \
					"$IMAGE_PIXMAP_WIDTH" "$IMAGE_PIXMAP_HEIGHT" \
					"$IMAGE_PIXMAP_IMAGE_QUALITY"
				;;
			esac

			if [ -s "$pixmap_bg" ]; then
				ln -sf "$pixmap_bg" "$pixmap_out"
			else
				varname_img_pixmap=
			fi
		fi
	else
		varname_img_pixmap="$pixmap_out"
	fi
}

get_pixmap_cursor () { # $1-varname_image_cursor
	local -n varname_image_cursor="$1"
	varname_image_cursor="$(readlink "$PIXMAP_CURSOR")"
}

set_pixmap_cursor () { # $1-fullpath
	ln -sf "$1" "$PIXMAP_CURSOR"
}

unset_pixmap_cursor () {
	rm -f "$PIXMAP_CURSOR"
}

