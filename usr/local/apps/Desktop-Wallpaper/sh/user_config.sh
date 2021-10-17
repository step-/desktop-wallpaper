# This POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && export __loaded_user_config=$(($__loaded_user_config +1)) && echo >&2 "user_config.sh{$__loaded_user_config}"

# tsort var:USRDIR file:CONFIG_FILE
# tsort sh/user_config.sh file:CONFIG_FILE
# tsort func:get_rox_pinboard_bg_color sh/user_config.sh

#######################################################################
#                   CREATE / READ USER CONFIGURATION                  #
#######################################################################

# TL;DR: (create and) read user's preferences
# Unexported variables that the user can change via dialog_config.
# Some variables do get exported in AppRun after sourcing this file.

export CONFIG_FILE="$USRDIR/preferences"

## Parse options -config-file and -create-config-file early

while (( $# )); do
	case "$1" in
		-config-file=*) CONFIG_FILE="${1#*=}" ;;
		-create-config-file) configuration_was_updated=1 ;;
		--) shift; break ;;
	esac
	shift
done

# ------------------------------------------------------------ #

if [ ! -s "$CONFIG_FILE" ]; then
	mkdir -p "${CONFIG_FILE%/*}" && : > "$CONFIG_FILE"
fi
. "$CONFIG_FILE"
exec 3>> "$CONFIG_FILE"

printf "%s=%q\n" >&3 "SLIDEDIR" "${SLIDEDIR:-$SYSTEM_WALLPAPER_DIR}"
printf "%s=%q\n" >&3 "RANDOM_IMAGE" "${RANDOM_IMAGE:-false}"
printf "%s=%q\n" >&3 "INT" "${INT:-15}"
printf "%s=%q\n" >&3 "SHUFFLER" "${SHUFFLER:-$DEFAULT_SHUFFLER}"
printf "%s=%q\n" >&3 "FILER" "${FILER:-$DEFAULT_FILER}"
printf "%s=%q\n" >&3 "IMGEDITOR" "${IMGEDITOR:-$DEFAULT_IMGEDITOR}"
printf "%s=%q\n" >&3 "VIEWER" "${VIEWER:-$DEFAULT_VIEWER}"
printf "%s=%q\n" >&3 "SHOW_EXIT_DIALOG" "${SHOW_EXIT_DIALOG:-true}"
printf "%s=%q\n" >&3 "PREFERRED_IMAGE_FORMAT" "${PREFERRED_IMAGE_FORMAT:-$WALLPAPER_PREFERRED_IMAGE_FORMAT}"
printf "%s=%q\n" >&3 "IMAGE_PIXMAP_IMAGE_QUALITY" "${IMAGE_PIXMAP_IMAGE_QUALITY:-$PIXMAP_IMAGE_QUALITY}"
printf "%s=%q\n" >&3 "IMAGE_WPIMAGE_IMAGE_QUALITY" "${IMAGE_WPIMAGE_IMAGE_QUALITY:-$WALLPAPER_IMAGE_QUALITY}"

if [ -z "$BG_COLOR" ]; then
	__p="${PINBOARD_FILE%/*}/Options"
	[ -s "$__p" ] || __p="$SYSTEM_ROX_DIR/Options"
	if [ -s "$__p" ]; then get_rox_pinboard_bg_color "$__p" BG_COLOR; fi
	printf "%s=%q\n" >&3 "BG_COLOR" "${BG_COLOR:-00/00/00}"
	unset __p
fi

exec 3>&-
. "$CONFIG_FILE"

