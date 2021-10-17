# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_authority_rox=$(($__loaded_authority_rox +1)) && echo >&2 "authority_rox.sh{$__loaded_authority_rox}"

# tsort sh/cache.sh sh/authority_rox.sh
# tsort sh/declare_constants.sh sh/authority_rox.sh
# tsort sh/authority_rox.sh func:get_rox_pinboard_bg_color

# depend xml2
# http://distro.ibiblio.org/fatdog/source/800/xml2-0.5.tar.gz

#######################################################################
#                          WALLPAPER AUTHORITY                        #
#######################################################################

# {N0} Which is the authoritative keeper of the current wallpaper state?  It
# could be, this program¹; ROX-Filer's pinboard file²; or some other program³.
# Since Fatdog64's desktop is entangled with ROX-Filer, this program's choice
# is ROX-Filer's pinboard.
# _____
# [1] Is this program the only method able to set the wallpaper in the system?
#     Cf. get_apprun_wallpaper_state.
# [2] Is ROX-Filer's "Set backdrop" action the only method to set the wallpaper
#     in the system?  Cf. get_rox_wallpaper_state.

get_rox_wallpaper_state () { # $1-varname_mode $2-varname_img {{{1
# Return current wallpaper mode and image path (rox calls them style and backdrop)
# See comments in get_rox_backdrop

	local -n varname_mode="$1" varname_img="$2"
	local pair IFS

	varname_mode= varname_img=
	if get_rox_backdrop "$PINBOARD_FILE" pair; then
		IFS=$'\n'; set -- $pair
		varname_mode="$1" varname_img="$2"
	fi
}

get_rox_backdrop () { # $1-pinboard-file $2-varname_pair {{{1
# Input file $1 is an XML pinboard file containing a backdrop tag: e.g.
#   <backdrop style="Stretched">IMAGE_PATH</backdrop>
# IMAGE_PATH can be a regular file path or a Z-encoded path (Cf. sh/cache.sh).
# It will include HTML hex entities, e.g. "&#x<hex digits>;"
# Return: in $varname_pair: mode (mapped from style) and path extracted from
# the pinboard file as a newline-separated string "mode\npath"
# Hex HTML entities are replaced with their unicode characters.
# Style is spelled as an en_UK imperative verb for reuse with rox RPC.

	local inf="$1" s path style mode
	local -n varname_pair="$2"; shift
	varname_pair=

	while IFS= read -r s; do
		[[ "$s" == "/pinboard/backdrop/@style="* ]] && style="${s#*=}" && continue
		[[ "$s" == "/pinboard/backdrop="* ]] && path="${s#*=}" && break
	done < <(xml2 < "$inf")

	# map rox:style to apprun:mode
	case "$style" in
		"Scale"*   ) mode="Scale" ;;
		"Fit"*     ) mode="Fit" ;;
		"Tile"*    ) mode="Tile" ;;
		"Stretch"* ) mode="Stretch" ;;
		*          ) mode="Centre" ;;
	esac

	[[ "$mode" == "Stretch" ]] &&
		has_cached_reshaped_path "Spread" "$path" &&
		mode="Spread" # {N1}

	varname_pair="$mode"$'\n'"$path"
}

get_rox_pinboard_bg_color () { # $1-options-file $2-varname_color {{{1
# Input file $1 is an XML options file containing the color tag: e.g.
#   <Option name="pinboard_bg_colour">#f8f8ffffd8d8</Option>
# Return: in $varname_color the hexadecimal color formatted as "rr/gg/bb".
# This format can be used easily for HTML style colors ("#${color//\//}")
# and NetPBM style colors ("rgb:$color").

	local inf="$1" s
	local -n varname_color="$2"; varname_color=
	while read s; do
		if [[ "$s" == *'<Option name="pinboard_bg_colour"'* ]]; then
			s="${s#*>#}"; s="${s%%<*}"
			s="${s:0:2}/${s:4:2}/${s:8:2}"
			varname_color="$s"
			break
		fi
	done < "$inf"
}

