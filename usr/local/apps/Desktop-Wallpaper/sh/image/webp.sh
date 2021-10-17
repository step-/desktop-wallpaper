#! This POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && export __loaded_webp=$(($__loaded_webp +1)) && echo >&2 "webp.sh{$__loaded_webp}"

# require: libwebp

# for get_pixmap_new
# transparent => transparent: WEBP
# animated => still: WEBP
webp_to_pixmap () { webp_to_png "$1" "$2"; }

# for status_bar_msg
webp_extract_meta () { # $1-img_path => $meta
# Set meta="WxH a=B", B:="0"|"1"
	local imgf="$1" w=-1 h=-1 a=0 x1 x2 t
	meta="0x0"
	while read x1 x2 t; do
		case "$x1" in
			"Animation:")
				[ 0 -lt "$x2" ] && a="$x2"
				;;
			"Canvas")
				[ "size" = "$x2" ] &&
				[ 0 -gt "$w" ] &&
				[ 0 -gt "$h" ] &&
				w="${t%% *}" h="${t##* }"
				;;
			"Width:")
				[ 0 -gt "$w" ] && w="$x2"
				;;
			"Height:")
				[ 0 -gt "$h" ] && h="$x2"
				;;
		esac
		[ $w -gt 0 -a $h -gt 0 -a $a -gt 0 ] && break
	done <<- EOF
$(LANG=C webpinfo "$imgf")
EOF
	meta="${w}x${h} a=$a"
}

# webp_extract_meta_not_animated () { # $1-img_path => $meta
# 	webp_to_pnm () { dwebp -quiet -o - -ppm -- "$1"; }
# 	extract_image_meta "$1" webp_to_pnm
# }

# for reshape_image
# transparent => transparent: WEBP
# animated => still: WEBP
webp_to_pnm () { pngtopam -alphapam "$1"; } # PNG caming from webp_to_pixmap

# ------------------------------------------------------------ #

webp_to_png () { # [-h=height] $1-webp_filepath $2-png_filepath
# webp_filepath can be either a single frame webp or a webp animation
# png_filepath can be "-" for stdout

	local height
	if [[ "$1" == -h=* ]]; then height="${1#*=}"; shift; fi
	local webpf="$1" pngf="$2" meta a=0

	# -----------------------------------------------------
	# this dependency is outside sh/image
	# tsort func:get_meta sh/image/webp.sh
	# -----------------------------------------------------
	get_meta "$webpf" meta # => $meta "WxH a=B"

	if [ "${meta#* }" != "a=0" ]; then
		# extract animation's first frame ignoring verbose info on stderr
		webpmux -get frame 1 -o "-" -- "$webpf" 2> /dev/null |
			dwebp ${height:+-resize 0 $height} -quiet -o "$pngf" -- "-"
	else
		dwebp ${height:+-scale 0 $height} -quiet -o "$pngf" -- "$webpf"
	fi
}

