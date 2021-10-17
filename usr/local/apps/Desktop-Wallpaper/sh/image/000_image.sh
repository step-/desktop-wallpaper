# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_image=$(($__loaded_image +1)) && echo >&2 "image.sh{$__loaded_image}"

#######################################################################
#                          IMAGE SUPPORT                              #
#######################################################################

# TL;DR: is_supported_image $1 by file name extension <EXT>
#   call_image_func $1 $2 ... => source/call <EXT>($1)_$2 ...

is_supported_image () { # $1-filepath
	[[ "${1,,}" =~ "."(jpe?g|png|svg|webp|gif|tiff?|bmp)$ ]]
}

__eregexp_is_supported_image="\.(jpe?g|png|svg|webp|gif|tiff?|bmp)$"

get_supported_image_mime_types () { # $1-varname_mimetype_list
	local -n varname_mime_type_list="$1"
	# sorted alphabetically
	varname_mime_type_list="image/bmp|image/gif|image/jpeg|image/png|image/svg+xml|image/tiff|image/webp"
}

# ------------------------------------------------------------ #

call_image_func () {
# $1-input_image $2-function_name_suffix $3@-function_arguments
# Call image-format-specific function: <EXT>_$2 $3... If the function is
# undefined (declare -F) for the input image type determined by $1's file
# extension (<EXT>) use predefined function __fallback_$2 instead.
# Call the function with positional parameters $3 $4... and return its status.
# Example:
#  call_image_func "/path/to/image.png" to_pixmap "$input" "$output"
#  calls:  png_to_pixmap "$input" "$output"   if defined
#  otherwise: __fallback_to_pixmap "$input" "$output"

	# if input is invalid bail out WITHOUT ERROR
	is_supported_image "$1" && [ -f "$1" ] || return 0 # keep

	local EXT="${1##*.}"; EXT="${EXT,,}"
	local func="${EXT}_$2" fallback="__fallback_$2"
	shift 2
	declare -F "$func" > /dev/null || func="$fallback"
	((DEBUG)) && dprint_basename "$func" "$@" >&2
	# LANG="C" to ensure English error messages for stderr filter coprocess
	LANG="C" "$func" "$@" 2> "$RUNTIME_DIR/stderr" # see image_stderr.sh
}

# ------------------------------------------------------------ #

__pixbuf_to_pam () { # $1-gtkimage [$2-long_side]
# Convert any image that can be read by an installed GDK pixbufloader library,
# hereafter called a "gtkimage", to a NetPBM PAM image with alpha transparency.
# The output image can be scaled DOWN by passing the long-side size in px ($2).
# No scaling occurs if $1's long side is less than $2.
# If $2 is omitted it defaults to the screen long side.
# See also note {N2} in image_pixmap.sh.
	local in_gtkimg="$1" side="$2"
	local png="$RUNTIME_DIR/.$FUNCNAME.$$.$RANDOM.png"
	trap "rm -f '$png'" RETURN
	((side)) || side=$((SCREEN_WIDTH > SCREEN_HEIGHT ? SCREEN_WIDTH : SCREEN_HEIGHT ))
	gdk-pixbuf-thumbnailer -s "$side" -- "$in_gtkimg" "$png"
	pngtopam -alphapam "$png"
}

