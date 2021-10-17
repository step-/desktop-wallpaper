# This POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && echo >&2 "declare_constants.sh{${__loaded_declare_constants:-1}}"

#######################################################################
#                       EXPORT READ-ONLY GLOBALS                      #
#######################################################################
export __loaded_declare_constants=$(( $__loaded_declare_constants +1 ))

# TL;DR: exported read-only global variables

[ "$BASH" ] && decl="declare" exp="-x" const="-r" || decl="" exp="export" const=""

# User's shell profile can override this location by setting WALLPAPER_CACHEROOT
# Location of cached files. It's OK to delete directory contents when App isn't running.
$decl $exp $const	CACHEROOT_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/desktop-wallpaper"
$decl $exp $const	CACHEROOT="${WALLPAPER_CACHEROOT:-$CACHEROOT_HOME}"

# Need at least gtkdialog-0.7.21
$decl $exp $const	GTKDIALOG="${GTKDIALOG:-gtkdialog}"

# Height in px of preview images.
$decl $exp $const	IMAGE_PIXMAP_HEIGHT="200"

# Image quality of preview images.
$decl $exp $const	PIXMAP_IMAGE_QUALITY="JPEG=40 WEBP=75" # 0-100

# Image quality of wallpaper images.
$decl $exp $const	WALLPAPER_IMAGE_QUALITY="JPEG=75 WEBP=75" # 0-100

# Default preferred image format of cached previews, and cached and exported
# wallpapers : JPEG or WEBP
$decl $exp $const	WALLPAPER_PREFERRED_IMAGE_FORMAT="WEBP"

# On program start $STATE_AUTHORITY provides the path of the currently
# displayed desktop wallpaper and possibly the state of other persistent
# variables.  Possible values: "rox", "self".
$decl $exp $const	STATE_AUTHORITY="rox"

# If "true" then application state files aren't deleted when the GUI exits.
# "true" must be set if STATE_AUTHORITY is "self".
$decl $exp $const	PERSIST_SELF_STATE="false"

# Fatdog64 - PINBOARD_FILE as set in /usr/bin/rox-desktop
$decl $exp $const	PINBOARD_FILE="$HOME/.config/rox.sourceforge.net/ROX-Filer/PuppyPin"

# ROX-Filer system configuration directory
$decl $exp $const	SYSTEM_ROX_DIR="/etc/xdg/rox.sourceforge.net/ROX-Filer"

# Default program preferences
$decl $exp $const	DEFAULT_FILER="rox"
$decl $exp $const	DEFAULT_IMGEDITOR="defaultpaint"
$decl $exp $const	DEFAULT_SHUFFLER="shuf"
$decl $exp $const	DEFAULT_VIEWER="defaultimageviewer"

# Location of runtime files
$decl $exp $const	RUNTIME_DIR="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/runtime-$USER}/desktop-wallpaper"

# System wallpaper directory
$decl $exp $const	SYSTEM_WALLPAPER_DIR="/usr/share/backgrounds"

# System wallpaper path prefixed with reshape mode ':'
$decl $exp $const	SYSTEM_WALLPAPER_MODE_PATH="Spread:/usr/share/backgrounds/Fatdog64-700.jpg"
# Fatdog64 800 /etc/xdg/rox.sourceforge.net/ROX-Filer/PuppyPin

# User's shell profile can override this location by setting WALLPAPER_USRDIR.
# User configuration and persistent program state files
$decl $exp $const	USRDIR_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/desktop-wallpaper"
$decl $exp $const	USRDIR="${WALLPAPER_USRDIR:-$USRDIR_HOME}"

unset decl exp const

