# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_impress_backend_rox=$(($__loaded_impress_backend_rox +1)) && echo >&2 "impress_backend_rox.sh{$__loaded_impress_backend_rox}"

#######################################################################
#                       ROX IMPRESSION BACK-END                       #
#######################################################################
# ROX-Filer back-end for function impress_wallpaper

# Rox's XML pinboard_file includes <pinboard><backdrop>, which sets the file
# path of the wallpaper image. Rox provides a method to set the backdrop of the
# active pinboard, but no method to find out the active pinboard's file path,
# or to set the backdrop of an inactive pinboard file. Rox only provides and
# RPC method to set the backdrop of the active pinboard.  Rox's command-line
# option -p to set the active pinboard file.  Command ps can show if rox was
# started with option -p hence which pinboard file was in use back then.
# However, if rox -p is used a second time to change the active pinboard file,
# rox will not restart therefore ps will not show the path of the updated
# pinboard file.
#
# Upon calling the SetBackdrop RPC method, if there is no previous active
# pinboard rox displays error dialog, "No active pinboard...Using the 'Default'
# pinboard", which causes a second pinboard ('Default') to come into existence.
# Clicking the desktop switches between the Puppy pinboard and the Default
# pinboard, which is unexpected and quite confusing.  Therefore, before calling
# SetBackdrop we need to test if there is an active pinboard file and if it is
# "$1". If so we shall not activate the pinboard again to avoid an unnecessary
# but noticeable screen update.
#
# In summary, the steps are:
# 1) activate the pinboard at most once
# 2) set the backdrop on each invocation

activate_rox_pinboard () { # $1-pinboard_file (full path!)
  local pinboard_file="$1"

  ### Look for evidence that the pinboard file is already active to
  # avoid another activation.

  # 1. Environment variable LIVE is set if AppRun's gtkdialog is running and is
  # my ancestor. Then assume that AppRun activated the pinboard.
  [ -n "$LIVE" ] && return

  # 2. Environment variable WALLSLIDE_IMPRESSIONS is non-empty if wallslide is
  # running and is my ancestor.  If wallslide impressed at least one background
  # then rox's pinboard is surely active.
  (( WALLSLIDE_IMPRESSIONS )) && return

  # So, no gtkdialog nor wallslide, e.g. command APPRUN/cli /path/to/image.jpg
  # 3. See if ROX-Filer is running with a $pinboard_file argument
  pgrep -u "$USER" -a ROX-Filer |
    grep -q -- "-p $pinboard_file\|--pinboard=$pinboard_file" && return

  # Since there is no evidence of an active pinboard file let's set one now.
  # If a back-end rox isn't already running, this rox -p will become the back-end.
  (cd $HOME; rox -p "$pinboard_file")
}

set_rox_backdrop () { # $1-backdrop_image (full path) $2-reshaping_mode
# Upon setting $backdrop_image in $PINBOARD_FILE, rox updates "<pinboard>" with
# "...<backdrop>$backdrop_image</backdrop>..." overwriting the previous
# "<backdrop>" value, if any.
# If rox finds that $backdrop_image is an invalid image type it deletes
# "<backdrop>" and shows "removing the backdrop" in a modal dialog. At this
# point there is no visible backdrop (desktop wallpaper).  While rox is
# displaying the modal dialog it doesn't accept further RPC, which makes it
# impossible to set another backdrop until the user has dismissed the modal.
# Therefore this function doesn't try to determined if $backdrop_image was
# successfully set.
  local backdrop_image="$1" style

  apprun_mode_to_rox_style "$2" style # see note {N3} in sh/mode.sh

  ((DEBUG)) && dprint "$FUNCNAME:$LINENO" "rox --RPC '$style:$backdrop_image'" >&2
  rox --RPC << EOF
<env:Envelope xmlns:env="http://www.w3.org/2001/12/soap-envelope">
 <env:Body xmlns="http://rox.sourceforge.net/SOAP/ROX-Filer">
  <SetBackdrop>
   <Filename><![CDATA[$backdrop_image]]></Filename>
   <Style>$style</Style>
  </SetBackdrop>
 </env:Body>
</env:Envelope>
EOF
}

