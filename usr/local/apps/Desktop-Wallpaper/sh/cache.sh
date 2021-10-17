# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_cache=$(($__loaded_cache +1)) && echo >&2 "cache.sh{$__loaded_cache}"

#######################################################################
#                            CACHE SUPPORT                            #
#         The Kingdom of Zz (/ziː/ /zed/) - know your path!           #
#######################################################################

# Z-encoded paths
# ===============
#
# Under Z-encoding an origin path is rewritten as the cached path:
#
#  ${CACHEROOT}'/'[<sub>'/'][<prefix>${Zp}]dirname>${Z}<filename>${Ze}<ext>
#
# where <dirname>${Z}<filename><ext> ­ replacing all occurrences of ${Z} with
# '/' ­ is the origin path.  <...> parts shall not include ${Z} and ${Ze}.
# <filename>, <ext> and <prefix> shall not include '/' and ${Zp}.
# <sub> is a sub-path under $CACHEROOT.
# <ext> is the origin basename's extension, e.g. ".jpg" ­ possibly followed by
# more extensions, see next paragraph. An empty origin extension is invalid.
# Use get_cached_path_new to create a Z-encoded cached path.

# As the origin image progresses through transformation stages, it is necessary
# to change its format and append a new filename extension to the cached path.
# Old extensions cannot be removed.  Extensions shall start with '.' and shall
# not include ${Ze}.
# Use get_cached_add_extension to append a new extension to a cached path.

declare -x -r  Z=$'\u233F' # U+233F ⌿ APL functional symbol slash bar
declare -x -r Zp=$'\u233D' # U+233D ⌽ APL functional symbol circle stile
declare -x -r Ze=$'\u2340' # U+2340 ⍀ APL functional symbol backslash bar

# Example
# origin             : /path/to/img.bmp
# cached minimal     : ${CACHEROOT}/⌿path⌿to⌿img⍀.bmp
# cached transformed : ${CACHEROOT}/sub/Spread⌽⌿path⌿to⌿img⍀.bmp.jpg

# ------------------------------------------------------------ #
# Identify the pathname of a cached file

# While the following condition is more precise...
# has_cached_path () { [[ "$1" == "$CACHEROOT/"* || "$1" == "$CACHEROOT_HOME/"* ]]; }
# ...when it comes to matching mixed CACHEROOTs this condition is more useful
has_cached_path () { [[ "$1" == "/"?*"/$Z"?*"$Ze"?* || "$1" == "/"?*"$Zp$Z"?*"$Ze"?* ]] ; }

# ------------------------------------------------------------ #
# with ../../test/unit/cache_001.sh

get_cached_path_new () { # $1-origin_path $2-sub $3-prefix $4-varname_cached_path
# Return 0 and Z-encoded origin_path in varname_cached_path.
# Return 1 and varname_cached_path empty if arguments violate Z-encoding rules
# or if origin_path is empty.

# {N7} Note that passing a cached path as $1 is invalid by Z-encoding rules,
# and that all get_<x>_new functions ultimately call get_cached_path_new.
# Therefore, to get a new <x> for a cached path $cp use:
#   get_cached_origin $cp origin_path && get_<x>_new "$origin_path" x.

	local op="$1" sub="${2:+/$2}" prefix="$3"
	local -n varname_cached_path="$4"; varname_cached_path=
	local ext dirname filename err=1
	if [[ -n "$op" &&
		"$prefix" != *"/"* &&
		"$prefix ${op##*/}" != *"$Zp"* &&
		"$*" != *"$Z"*
	]]; then
		ext="${op##*/}" # basename for now
		[[ "$ext" == *"."* ]] && ext=".${ext##*.}" || unset ext
		if [[ -n "$ext" && "$ext" != *"$Ze"* ]]; then
			dirname="${op%/*}"
			filename="${op##*/}"; filename="${filename%$ext}"
			varname_cached_path="$CACHEROOT$sub/${prefix:+$prefix$Zp}${dirname//\//$Z}$Z$filename$Ze$ext"
			err=0
		fi
	fi
	return $err
}

get_cached_dirname () { # $1-cached_path $2-varname_dirname
# Z-encoded
	local cp="$1" p
	local -n varname_dirname="$2"
	p="${cp##*/}"
	p="${p#*$Zp}"
	varname_dirname="${p%$Z*}"
	if [[ -n "$p" && -z "$varname_dirname" ]]
	then varname_dirname="$Z"
	fi
}

get_cached_basename () { # $1-cached_path $2-varname_basename
# not Z-encoded, includes all extensions
# For a method to get the Z-encoded basename see rm_cached_file_and_siblings

	local cp="$1" p
	local -n varname_basename="$2"
	p="${cp##*$Z}"
	p="${p#*$Zp}"
	p="${p##*$Z}"
	varname_basename="${p/$Ze/}"
}

get_cached_prefix () { # $1-cached_path $2-varname_prefix
	local cp="$1" p
	local -n varname_prefix="$2"
	p="${cp##*/}"
	if [[ "$p" == *"$Zp"* ]]
	then varname_prefix="${p%%$Zp*}"
	else varname_prefix=
	fi
}

get_cached_origin () { # $1-cached_path $2-varname_origin_path
# not Z-encoded, includes the origin extension only

	local cp="$1" p
	local -n varname_origin_path="$2"
	if [ -n "$cp" ]; then
		p="${cp##*/}"
		p="${p#*$Zp}"
		[[ "$p" =~ (.*)"$Ze"(\.[^.]+) ]]
		p="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
		varname_origin_path="${p//$Z/\/}"
	fi
}

# ------------------------------------------------------------ #
# with ../../test/unit/cache_002.sh

get_cached_add_extension () { # $1-cached_path $2-extension $3-varname_cached_path
	local cp="$1" ext="${2#.}"
	local -n varname_cached_path="$3"
	[[ "${cp##*/}" == *"$Ze."?* ]] && ext=".$ext" || ext="$Ze.$ext"
	varname_cached_path="$cp$ext"
}

# ------------------------------------------------------------ #

# {N1} Clicking 'Preview' and 'Apply' or running a
# slideshow gets the selected image cached with Z-encoding parts
# <sub>=".$SCREEN_ASPECT_RATIO" and <prefix>=$mode. The file will remain
# cached also after exiting the GUI, unless it isn't created by a slideshow¹
# or the user clicks 'Clear'.
# _____
# [¹]After swapping in a new slide wallslide purges the previous spreaded file.

has_cached_reshaped_path () { # $1-$mode $1-cached_path
	local mode="$1" cp="$2" prefix
	has_cached_path "$cp" || return 1
	get_cached_prefix "$cp" prefix
	[[ "${mode,,}" == "${prefix,,}" ]]
}

# ------------------------------------------------------------ #
# test rm_cached_file_and_siblings with this command:
#  AppRun -play=Spread,5 & sleep 17; AppRun -play-stop
# watch files in $CACHEROOT/.{$aspectratio,wp}/ come and go
# every 5 seconds for three cycles

rm_cached_file_and_siblings () { # [rm options '--'] cached_path
# Remove all same-depth file siblings of a cached file. For example, passing
# rm_cached_file_and_siblings a file taken from the tree below will remove the
# rest - files only, not directories:
# $CACHEROOT        (Z-encoding omitted for clarity)
#   `- .{wp,pixmap,any_name}/file.*
#   `- .160/file.*
#   `- .160/Spread:file.*

	local cp="${!#}" z_prefix z_dirname z_basename p
	if has_cached_path "$cp"; then

		# delete $cp from positional parameters
		set -- "${@: 1: $#-1}"

		# need these for find command
		get_cached_prefix "$cp" z_prefix
		get_cached_dirname "$cp" z_dirname

		# need z_basename too
		p="${cp##*/}"
		p="${p#$z_prefix$Zp}"
		p="${p#$z_dirname$Z}" # z_basename with all extensions
		z_basename="${p%%.*}" # z_basename without extensions

		# find $cp and siblings regardless of <z_prefix>
		find "${cp%/*}/.." -mindepth 2 -maxdepth 2 \
			\( -type f -o -type l \) \
			\( -name "$z_dirname$Z$z_basename.*" \
			-o -name "$z_prefix$Zp$z_dirname$Z$z_basename.*" \
			\) \
			-delete
	fi
}

empty_cache () {
	find "$CACHEROOT/".[a-zA-Z0-9_]* -mindepth 1 \
		\( -type f -o -type l \) \
		-delete
}

