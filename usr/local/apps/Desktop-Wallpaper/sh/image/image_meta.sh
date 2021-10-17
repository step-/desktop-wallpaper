# This POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && export __loaded_image_meta=$(($__loaded_image_meta +1)) && echo >&2 "image_meta.sh{$__loaded_image_meta}"

#######################################################################
#                     EXTRACT IMAGE META DATA                         #
#######################################################################

# TL;DR: EXT_extract_meta () $1 => $meta

# An image meta function for the status bar widget returns data by setting
# variable 'meta' (string) outside its scope.
# $meta must start with "WxH", where W and H are the image width and height
# pixel dimensions.  Set meta="0x0" to signal a corrupt input file.
# Optionally, $meta can continue with more words representing various image
# properties However, be mindful of enabling translation of such new words,
# and remember that WxH only is relied upon for further processing.
# The same input type can have multiple extension, e.g. JPG/JPEG.  Define a
# function for each supported extension.

# Functions set $meta outside their scope
# -------------------------------------------------------
__fallback_extract_meta () { meta="$FUNCNAME"; }
jpeg_extract_meta () { jpg_extract_meta   "$1"; }
jpg_extract_meta  () { __pam_extract_meta "$1" "jpegtopnm -quiet --" ; }
bmp_extract_meta  () { __pam_extract_meta "$1" "bmptopnm -quiet --"  ; }
gif_extract_meta  () { __pam_extract_meta "$1" "giftopnm --"         ; }
png_extract_meta  () { __pam_extract_meta "$1" "pngtopam --"         ; }
tif_extract_meta  () { __pam_extract_meta "$1" "tifftopnm -quiet --" ; }
tiff_extract_meta () { tif_extract_meta   "$1"; }

# ------------------------------------------------------------ #

__pam_extract_meta () { # $1-img [$2-to_netpbm_command]
	if [ -z "$2" ]
	then set -- $(pamfile -machine -- "$1")
	else set -- $($2 "$1" 2> /dev/null | pamfile -machine)
	fi
	# 0 File: path': '
	# 1 Format: 'PAM', 'PBM', 'PGM', or 'PPM'
	# 2 Subformat: 'PLAIN' or 'RAW'
	# 3 Width: in pixels, in decimal
	# 4 Height: in pixels, in decimal
	# 5 Depth: in decimal
	# 6 Maxval: in decimal (1 if image is PBM)
	# 7 Tuple: type (emulated if the image is not PAM)
	local p
	for p; do case "$p" in
		"PAM"|"PBM"|"PGM"|"PPM" ) break;;
		* ) shift;;
	esac; done
	[ -n "$1" ] && meta="${3}x${4} $5/$6 $7" || meta="0x0"
}

