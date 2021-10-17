#! this POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && export __loaded_svg=$(($__loaded_svg +1)) && echo >&2 "svg.sh{$__loaded_svg}"

# require: librsvg for rsvg-convert

# for get_pixmap_new
# transparent => transparent: SVG
# animated => still: SVG
#svg_to_pixmap () { rsvg-convert -f png -a -h "$IMAGE_PIXMAP_HEIGHT" "$1" > "$2"; } # ok but dependent on librsvg

# for status_bar_msg
svg_extract_meta () { __pam_extract_meta "$1" "__pixbuf_to_pam"; }

# for reshape_image
# transparent => transparent: SVG
# animated => still: SVG
#svg_to_pnm () { rsvg-convert -f png -- "$1" | pngtopam -alphapam -- "-"; } # ok but dependent on librsvg

