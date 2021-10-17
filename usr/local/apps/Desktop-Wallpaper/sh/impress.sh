# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_impress=$(($__loaded_impress +1)) && echo >&2 "impress.sh{$__loaded_impress}"

#######################################################################
#             IMPRESS THE DESKTOP WALLPAPER WITH AN IMAGE             #
#######################################################################

# TL;DR: change ROX-Filer's backdrop; consequently set_apprun_wallpaper_state
# (if invoked by GUI, except GUI slideshow menu entry)

# Notable input environment variables: WALLSLIDE_IMPRESSIONS, WALLSLIDE_INDEX

# Require ROX-Filer running (AppRun tests for rox's presence)
# If it isn't already running for $USER, its first invocation rox will
# 1) complain that it can't find dir ~/.icons to set link ~/.icons/ROX
# 2) daemonize and keep gtkdialog's parent process active after gtkdialog has closed.

# ------------------------------------------------------------ #

impress_wallpaper () { # $1-mode_period_input_image_fullpath
# $1          ::= [mode[','period]':']input_image_fullpath
# $input_img  ::= *'/'[mode':']filename
# $mode       ::= $RESHAPING_METHODS_EX

  local input_img="/${1#*/}"
  local x="${1%$input_img}";  x="${x%:}"
  local mode="${x%,*}"; x="${x#$mode}"; x="${x#,}"
  local period="${x#,}"
  local wallpaper_img
  ((DEBUG)) && dprint "$FUNCNAME:$LINENO" "mode($mode)" "input_img($input_img)" "period($period)" >&2

  [ -s "$input_img" ] || return 1

  [ "$mode" ] || get_apprun_wallpaper_state mode "!" "!"
  [ "$mode" ] || set_apprun_wallpaper_state "${mode:=Centre}" ! !
  get_canonical_mode "$mode" mode
    ((DEBUG)) && dprint "$FUNCNAME:$LINENO" "mode($mode)" "input_img($input_img)" "period($period)" >&2

  ## ROX-Filer's pinboard backdrop wants GtkImage pixmaps only.

  get_wpimage_new "$input_img" wallpaper_img &&
    [ -s "$wallpaper_img" ] ||
    # -----------------------------------------------------------
    return $? # without impressing the desktop
    # -----------------------------------------------------------

  ## Reshape wallpaper according to mode

  get_reshaped_image_new "$mode" "$wallpaper_img" cached_image \
    "$SCREEN_WIDTH" "$SCREEN_HEIGHT" ".$SCREEN_ASPECT_RATIO" \
    "$IMAGE_WPIMAGE_IMAGE_QUALITY" &&
    [ -s "$cached_image" ] &&
    wallpaper_img="$cached_image" ||
    # -----------------------------------------------------------
    return $? # without impressing the desktop
    # -----------------------------------------------------------

  ## Resolve symlinks
  # for cached wallpaper files that point to their origin image

  wallpaper_img="$(realpath "$wallpaper_img")"

  ## Impress the Desktop wallpaper

  activate_rox_pinboard "$PINBOARD_FILE"
  set_rox_backdrop "$wallpaper_img" "$mode"
  local ret=$? # ¹

  # [¹] We can't know for sure if the RPC in set_rox_backdrop succeeded in
  # changing the backdrop or if instead rox is stuck in its modal error dialog.

  ## Save new wallpaper state.¹

  # when invoked by a slideshow
  if [ -n "$WALLSLIDE_IMPRESSIONS" ]; then
    set_slideshow_state "$mode" "$wallpaper_img" "$input_img" "$WALLSLIDE_INDEX"

  # when invoked by GUI Preview mode or Apply button
  elif [ -n "$LIVE" ]; then
    set_apprun_wallpaper_state "$mode" "$wallpaper_img" "$input_img"
    ((DEBUG)) && get_apprun_wallpaper_state bg_mode bg_img bg_img_origin
    ((DEBUG)) && dprint_varname "${0##*/}:$LINENO ret($ret) set_apprun_wallpaper_state" bg_mode bg_img bg_img_origin >&2

  fi
  return $ret
}

