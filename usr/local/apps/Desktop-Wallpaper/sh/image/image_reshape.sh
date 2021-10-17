# This POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && export __loaded_image_reshape=$(($__loaded_image_reshape +1)) && echo >&2 "image_reshape.sh{$__loaded_image_reshape}"

#######################################################################
#           IMAGE TO PPM/PAM TO PIXMAP RESHAPING ENDPOINTS            #
#######################################################################

# TL;DR:
#   EXT_to_pnm () $1 (GtkImage pixmap) => $2 (PPM/PAM)
#     ↓
#    reshape_<mode>_image
#     ↓
#   EXT_from_pnm () $1 (PPM/PAM) => "-" (GtkImage pixmap) at $2 image quality level

# EXT_to_pnm and EXT_from_pnm functions for image_reshape provide the input and
# output endpoints to reshaping an image before the wallpaper is impressed.
# EXT_to_pnm converts $1 ­ output by EXT_to_pixmap ­ into a PPM/PAM file,
# which _must_ preserve $1's transparency.  EXT_from_pnm converts the PPM/PAM
# file $1 to a GtkImage pixmap format{N2} (JPEG and WEBP included at quality
# level $2) to be displayed as Desktop wallpaper.
# Note 1: in spite of the EXT in their name, EXT_from_pnm functions do not
# output EXT format necessarily.
# ____
# {N2}: see note {N2} in image_pixmap.sh

# Function names must start with the file name extension of the input type.
# The same input type can have multiple extension, e.g. JPG/JPEG.  Define a
# function for each supported extension.

# no transparency: JPEG
# transparent => transparent: BMP, PNG, GIF, TIFF
# animated => still: GIF
__fallback_to_pnm   () { __pixbuf_to_pam "$1"; }

# EXT_from_pnm functions aren't required to preserve transparency.

# see get_reshaping_output_formats
# (bad separation of concern here!)
__fallback_from_pnm () { __fallback_${PREFERRED_IMAGE_FORMAT}_from_pnm "$@"; }

# this will make most wallpapers JPEG
__fallback_JPEG_from_pnm () {
	local q="! $2 !"; q="${q#*JPEG=}"; q="${q%% *}"; case "$q" in *\!*) q=;; esac
	pnmtojpeg ${q:+-quality="$q"} "$1"
}
# this will make most wallpapers WEBP, which produces smaller file size than JPEG
__fallback_WEBP_from_pnm () {
	local q="! $2 !"; q="${q#*WEBP=}"; q="${q%% *}"; case "$q" in *\!*) q=;; esac
	cwebp -quiet ${q:+-q "$q"} -o - -- "$1"
}

jpg_to_pnm    () { jpegtopnm -quiet -- "$1"; }

jpeg_to_pnm   () { jpg_to_pnm "$1"; }

#bmp_to_pnm    () { bmptopnm -quiet -- "$1"; } # no transparency

png_to_pnm    () { pngtopam -alphapam -- "$1"; }
#png_from_pnm  () { pamtopng "$1"; } # much larger output size than jpeg/webp; transparency not needed at this stage

#gif_to_pnm    () { giftopnm "$1"; } # no transparency
#gif_from_pnm  () { pnmquant -quiet 256 "$1" | pamtogif -quiet "-"; } # ok but gif size > jpeg size

#tif_to_pnm    () { tifftopnm -quiet -- "$1"; } # cumbersome to extract transparency
#tif_from_pnm  () { pnmtotiff "$1"; } # ok but tif size > jpeg size

