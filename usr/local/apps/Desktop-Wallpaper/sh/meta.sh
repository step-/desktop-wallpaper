# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_meta=$(($__loaded_meta +1)) && echo >&2 "meta.sh{$__loaded_meta}"

#######################################################################
#                              META SUPPORT                           #
#######################################################################

# A meta file is a text file that holds meta information about a cached image.
# Meta files are cached for performance reasons.

get_meta_new () { # [-p] $1-in_img $2-varname_img_meta
# Return the cached path of a meta file corresponding to the input image $1.
# $1 can be an origin image file or a cached file.
# If the meta file doesn't exist it is created anew by calling an appropriate
# EXT_to_meta function.
# Option -p: mkdir -p "${2%/*}"

	local opt_p; [ "$1" = "-p" ] && opt_p=1 && shift
	local in_img="$1"
	local -n varname_img_meta="$2"; varname_img_meta=
	local meta_out img_origin meta

	# see {N7} in sh/cache.sh
	has_cached_path "$in_img" &&
		get_cached_origin "$in_img" img_origin &&
		[ -s "$img_origin" ] &&
		in_img="$img_origin"

	get_cached_path_new "$in_img" ".pixmap" "" meta_out &&
		if ((opt_p)); then mkdir -p "${meta_out%/*}"; fi ||
	# -----------------------------------------------------------------
		return $?
	# -----------------------------------------------------------------
	meta_out+=".meta"

	# if an up-to-date meta doesn't exist
	if [ "$in_img" -nt "$meta_out" ]; then

		# call an appropriate image-meta function
		call_image_func "$in_img" extract_meta "$in_img" # => $meta
		[[ "$meta" != "0x0"* ]] &&
			printf "%s\n" "$meta" > "$meta_out" && # cache vars
			varname_img_meta="$meta_out"
	else
		varname_img_meta="$meta_out"
	fi
}

# tsort sh/meta.sh func:get_meta

get_meta () { # $1-in_img $2_varname_meta
# Return image file $1's meta data in $2.
# $1 can be an origin image file or a cached file.
# The meta file is created if it doesn't already exist.

	local in_img="$1" metaf
	local -n varname_meta="$2"; varname_meta=
	get_meta_new "$1" metaf &&
		[ -s "$metaf" ] &&
		read varname_meta < "$metaf"
}

get_meta_image_dimensions () { # $1-in_img $2_varname_width $3_varname_out
# Return image file $1's width in $2 and height in $3.
# $1 can be an origin image file or a cached file.

	local in_img="$1" meta
	local -n varname_width="$2" varname_height="$3"; varname_width= varname_height=

	get_meta "$in_img" meta && # => $meta "WxH"[" ..."]
		meta="${meta%% *}" &&
		varname_width="${meta%x*}" varname_height="${meta#*x}"
}

