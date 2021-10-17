# This BASH file is sourced not run
((DEBUG)) && export __loaded_gui=$(($__loaded_gui +1)) && echo >&2 "gui.sh{$__loaded_gui}"

#######################################################################
#                              GOING GUI                              #
#######################################################################
# AppRun sources this file under an exclusive lock
# This file runs the main loop until exit
# - gtkdialog GUI and supporting functions
# - set signal traps
# - start and stop stderr filter coprocess
# - export gtkdialog/bash compatibility layer

readonly start_bg_mode="$1" start_bg_img="$2" start_bg_img_origin="$3"
# $start_bg_mode and $start_bg_img read from $PINBOARD_FILE
((DEBUG>1)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO" start_bg_mode start_bg_img start_bg_img_origin >&2
shift 3

#######################################################################
#                               BUTTONS                               #
#######################################################################

make_mode_button () { # $1-mode $2-bg_mode
  local label tooltip active mode="$1" active_mode="$2"
  get_localized_mode_label "$mode" label tooltip
  [ "$mode" = "$active_mode" ] && active='active="true"'
  echo "<radiobutton $active tooltip-markup=\"$tooltip\" label=\"$label\">
 <action>if true exec bash -c 'set_apprun_wallpaper_state \"$mode\" \"!\" \"!\" && trigger_mode_button \$LIVE'</action>
 <action>if true refresh:STATUSBAR</action>
</radiobutton>"
}

trigger_mode_button () { # $1-('true'|'false'|'apply')
# Stage or commit $FILE_CURSOR as the Desktop wallpaper.
# 'true'/'false' reflect the state of the $LIVE checkbox; 'apply' reflects the Apply button.
# 'true' denotes staging a wallpaper change while 'apply' denotes committing a wallpaper.

  local mode img img_origin="$FILE_CURSOR" # hold value
  case "$1" in "true"|"apply" )
    is_supported_image "$img_origin" && [ -s "$img_origin" ] &&
      impress_wallpaper_with_lock "$img_origin"
  esac &&
  case "$1" in
    "true"  )
      get_apprun_wallpaper_state mode img img_origin
      stage_change "$mode" "$img" "$img_origin"
      ;;
    "apply" )
      get_apprun_wallpaper_state mode img img_origin
      commit_change "$mode" "$img" "$img_origin" ;;
  esac
}
export -f trigger_mode_button

#######################################################################
#                              PIXMAP                                 #
#######################################################################

set -a
source "$APPDIR/sh/pixmap.sh"
source "$APPDIR/sh/meta.sh"
set +a

swap_pixmap () {
# Create a $PREFERRED_IMAGE_FORMAT preview image of $FILE_CURSOR and swap it into the gtkdialog PIXMAP widget.
# Input: gtkdialog variable FILE_CURSOR;
# Output: $PIXMAP_CURSOR links to the cached pixmap image file.
# If converting $FILE_CURSOR to a pixmap failed then $PIXMAP_CURSOR is removed.¹
# ____
# ¹ The alternative of linking $PIXMAP cursor to the origin image $FILE_CURSOR has two drawbacks:
# - The PIXMAP widget may not be able to display $FILE_CURSOR's image format,
#   see https://developer.gnome.org/gtk2/2.24/GtkImage.html;
# - The main window may become huge due to the large, unconstrained PIXMAP, see {N8}.
# Both issues can be fixed manually by removing file $PIXMAP_CURSOR and restarting.

  local pixmap image
  shopt -s nocasematch

  if [ -d "$FILE_CURSOR" ]; then               image="$FOLDER_THUMB"
  elif is_supported_image "$FILE_CURSOR"; then image="$FILE_CURSOR"
  else                                         image="$NONIMG_THUMB"
  fi

  get_pixmap_new "$image" pixmap
  [ -s "$pixmap" ] &&
    set_pixmap_cursor "$pixmap" ||
    unset_pixmap_cursor # instead of set_pixmap_cursor "$image"
}
export -f swap_pixmap

# ------------------------------------------------------------ #

status_bar_msg () {
# Emit content of the STATUSBAR widget.
# Gtkdialog calls this function immediately after swap_pixmap and when a mode
# button is clicked, see make_mode_button.
# Update: since STATUSBAR was set invisible, now $MAIN_DIALOG runs
# dialog_file_cursor_info to display the output of status_bar_msg when
# the user clicks the PIXMAP widget.

  [ -n "$FILE_CURSOR" ] || return 0
  local file_cursor="$FILE_CURSOR" # hold value
  shopt -s nocasematch
  local img pixmap p apprun_mode apprun_img apprun_img_origin
  # assemble the status line concatenating the following labels:
  local img_meta meta state name

  meta="$APP_NAME_VERSION" # fallback for unsupported image-type
  is_supported_image "$file_cursor" && img="$file_cursor"

  if [ -n "$img" ]; then
    ### Fill in $meta

    # Extract and cache image meta data
    if get_meta_new "$file_cursor" img_meta; then
      read meta < "$img_meta"

    else
      # the image-meta function reported a corrupt image or invalid file type
      # set meta= an informational message including $img's MIME-type
      local mime="$(file -i "$img")" # not rox -m!
      mime="${mime##*: }"; mime="${mime%%;*}"
      meta="$i18n_corrupt_file '${img##*.}'; $i18n_mimetype $mime"
    fi

    ### Fill in $state - sundry properties of this image/pixmap
    state=
    get_apprun_wallpaper_state apprun_mode apprun_img apprun_img_origin

    ## Is there also a cached spreaded image for this $img?
    if [ "Spread" = "$apprun_mode" ]; then
      get_cached_path_new "$img" ".$SCREEN_ASPECT_RATIO" "Spread" p

      [ -s "$p" ] && state="${i18n_cached}${state:+, $state}"
    fi

    ## Is the image the current wallpaper by AppRun's authority?
    # (AppRun's rather that Rox's authority to avoid extra processing.  In the
    # context of this function AppRun's and Rox's authorities coincide anyway,
    # as long as the slideshow isn't running; the slideshow sets the wallpaper
    # on its own schedule disjoint from $PIXMAP_CURSOR.)
    if [ "$img" = "$apprun_img_origin" ]; then
      get_localized_mode_label "$apprun_mode" locmode __ &&
      state="$i18n_cur_wallpaper $locmode${state:+, $state}"
    fi

    ## Fill in $name
    name="${img##*/}"

  else
    name="${FILE_CURSOR##*/}"
  fi

  ### Emit status line to the status bar widget
  echo -n "${meta:+$meta;}${state:+ $state;} $name"
}
export -f status_bar_msg

file_cursor_info () {
  local p="! $IMAGE_PIXMAP_IMAGE_QUALITY !";  p="${p#*$PREFERRED_IMAGE_FORMAT=}"; p="${p%% *}"; case "$p" in *\!*) p=;; esac
  local w="! $IMAGE_WPIMAGE_IMAGE_QUALITY !"; w="${w#*$PREFERRED_IMAGE_FORMAT=}"; w="${w%% *}"; case "$w" in *\!*) w=;; esac
{
  echo
  printf "$i18n_preferred_image_format_fmt\n" "$PREFERRED_IMAGE_FORMAT"
  printf "$i18n_subject_and_wallpaper_quality_fmt\n" "$PREFERRED_IMAGE_FORMAT" "$p" "$w"
  printf "$i18n_bg_color_preference_fmt\n" "$BG_COLOR"

  echo
  status_bar_msg; echo

  echo
  file "$FILE_CURSOR"

  echo
  command -v exiftool > /dev/null &&
    exiftool "$FILE_CURSOR" ||
    echo "$i18n_exiftool_not_found"
} | awk -f "$APPDIR/script/help_text_to_pango_markup.awk"
}
export -f file_cursor_info

#######################################################################
#                             MENU ITEMS                              #
#######################################################################
set -a

start_slideshow () {
  local p mode
  ((DEBUG)) && dprint_varname "$FUNCNAME" FILE_CURSOR >&2
  [ -d "$FILE_CURSOR" ] && p="$FILE_CURSOR" || p="$(dirname "$FILE_CURSOR")"
  get_apprun_wallpaper_state mode "!" "!"
  exec "$APPDIR/slideshow" -start "$mode:$p"
}

stop_slideshow () {
  exec "$APPDIR/slideshow" -stop
}

set +a
# ------------------------------------------------------------ #

#######################################################################
#                           ACTION BUTTONS                            #
#######################################################################
set -a

empty_cache_and_reset_wallpaper () {
  local img mode mode_cur bg_cur pixmap_cur pixmap_origin_cur __

  ## Stash wallpaper and pixmap cursor origins

  # the origin of the current wallpaper (best effort)
  get_rox_wallpaper_state mode img &&
    mode_cur="$mode" bg_cur="$img" &&
    has_cached_path "$img" &&
    get_cached_origin "$img" img &&
    [ -s "$img" ] && bg_cur="$img"

  # the origin of the current pixmap (best effort)
  get_pixmap_cursor pixmap_cur &&
    get_cached_origin "$pixmap_cur" img
    [ -e "$img" ] &&
    [[ "$img" != "$NONIMG_THUMB" && "$img" != "$FOLDER_THUMB" ]] &&
    pixmap_origin_cur="$img" &&
    has_cached_path "$img" &&
    get_cached_origin "$img" img &&
    [ -s "$img" ] && pixmap_origin_cur="$img"

  ((DEBUG)) && dprint_basename_varname "$FUNCNAME:$LINENO" "mode_cur" "bg_cur" "pixmap_origin_cur" >&2

  ## Reset cached pixmaps and reshaped wallpapers
  empty_cache

  # these two pixmaps need to exist (corner case)
  get_pixmap_new "$FOLDER_THUMB" __
  get_pixmap_new "$NONIMG_THUMB" __

  ## Refresh stashed wallpaper and pixmap cursor

  if [ -n "$bg_cur" ]; then

    # fall back for empty Rox backdrop style
    [ -z "$mode_cur" ] &&
      get_apprun_wallpaper_state mode_cur __ ___

    # refresh wallpaper
    impress_wallpaper_with_lock "${mode_cur:-Centre}:$bg_cur"
  fi

  # refresh pixmap cursor image and its cached meta
  if [ -n "$pixmap_origin_cur" ]; then
    FILE_CURSOR="$pixmap_origin_cur" swap_pixmap
    FILE_CURSOR="$pixmap_origin_cur" status_bar_msg > /dev/null
  fi
}

clicked_edit ()  {
  if [ -d "$FILE_CURSOR" ]; then
    clicked_filer
  else
    source "$CONFIG_FILE" && exec $IMGEDITOR "$FILE_CURSOR"
  fi
}

clicked_filer () {
  [ -d "$FILE_CURSOR" ] && set -- "$FILE_CURSOR" || set -- "$(dirname "$FILE_CURSOR")"
  source "$CONFIG_FILE" && exec $FILER "$1"
}

clicked_view ()  {
  # assume that the viewer accepts both a dir and a file
  source "$CONFIG_FILE" && exec $VIEWER "$FILE_CURSOR"
}

set +a
# ------------------------------------------------------------ #

#######################################################################
#                            INIT FOR GUI                             #
#######################################################################

# Traps
unset MAIN_DIALOG
source "$APPDIR/sh/trap.sh"
trap_with_arg on_signal HUP INT QUIT TERM EXIT

# ------------------------------------------------------------ #

# Create apprun's state files - these last only until the GUI exits, see on_signal.
[ -s "$start_bg_img_origin" ] &&
  initial_bg_img_origin="$start_bg_img_origin" || initial_bg_img_origin="$start_bg_img"
set_apprun_wallpaper_state "$start_bg_mode" "$start_bg_img" "$initial_bg_img_origin"
((DEBUG)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO set_apprun_wallpaper_state" start_bg_mode start_bg_img initial_bg_img_origin >&2

## Create wallpaper restore point.
# It will get restored if the user exits with unapplied changes.
set_restore_point "$start_bg_mode" "$initial_bg_img_origin"
((DEBUG)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO set_restore_point" start_bg_mode initial_bg_img_origin >&2

## Initialize undo stack
# Undoing is a GUI-only feature. It does not concern the slideshow - even when
# the latter starts from its GUI menu entry.
# Undo stack BOS = $initial_bg_img_origin.
# The restore point back-fills the stack when the stack is too short to pop
# the undo target - see also set_restore_point and undo_wallpaper_with_lock.
# The undo stack prefers origin images, that is, uncached ones, when these are
# available - see also impress_wallpaper_with_lock.
[ -s "$initial_bg_img_origin" ] &&
  bos="$start_bg_mode:$initial_bg_img_origin" ||
  bos="$SYSTEM_WALLPAPER_MODE_PATH" # "mode:path"
stack_clear undo && stack_push undo "$bos"
((DEBUG)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO undo-stack" bos >&2

# -------------------------------------------------------------------------- #
# Determine the default directory and file for the <chooser> widget
# (file requires patched gtkdialog).
# Fallback chain:
#    (0) $WALLPAPER_START_DIR from cli -> (1) current wallpaper¹ ->
# -> (2) slideshow directory -> (3) system wallpaper -> (4) $HOME
# ____
# ¹excluding cached folders

# (3)
chooser_default="/${SYSTEM_WALLPAPER_MODE_PATH#*/}" # file
# (2)
if ! [ -d "$SLIDEDIR" ]; then
  printf "$i18n_error_invalid_config_fmt\n" "$i18n_conf_slideshow_slide_dir" "$SLIDEDIR" >&2
else
  [ "$SLIDEDIR" = "${chooser_default%/*}" ] ||
    chooser_default="$SLIDEDIR" # folder
fi
# (1)
[ -s "$start_bg_img_origin" ] &&
  ! has_cached_path "$start_bg_img_origin" &&
  chooser_default="$start_bg_img_origin" # file
# (0)
[ -d "$WALLPAPER_START_DIR" ] &&
  chooser_default="$WALLPAPER_START_DIR" # folder

# (4) error catch-all
[ -d "$chooser_default" -o -d "${chooser_default%/*}" ] ||
  chooser_default="$HOME"
# gtkdialog can't parse "<" in <chooser><default> tag value
[[ "$initial_chooser_dir" != *"<"* ]] || chooser="$HOME"

((DEBUG)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO" chooser_default >&2

# $chooser_file XML fragments for gtkdialog
if [ -f "$chooser_default" ]; then
  # for gtkdialog patched with <chooser file="path">
  chooser_file="default-file=\"$chooser_default\""
  chooser_dir="<default>${chooser_default%/*}</default>"
  get_pixmap_new "$chooser_default" __
else
  # for regular gtkdialog - backward compatibility
  chooser_file=
  chooser_dir="<default>$chooser_default</default>"
fi

# ------------------------------------------------------------ #
# File selection patterns for the chooser widget
# (patterns requires patched gtkdialog).
get_supported_image_mime_types chooser_mime_types
chooser_mime_types="fs-filters-mime=\"image/*|$chooser_mime_types\""
# intentionally the gtkdialog patch lists patterns after mime-types so
# "image/*" is listed first and applied by default and "*" is listed last
chooser_patterns="fs-filters=\"*\""
((DEBUG)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO" chooser_mime_types chooser_patterns

# ------------------------------------------------------------ #

export FOLDER_THUMB="$APPDIR/media/th_folder.png" NONIMG_THUMB="$APPDIR/media/th_nonimg.png"

# create cache folder for pixmap files and two required pixmaps
get_pixmap_new -p "$FOLDER_THUMB" _p
get_pixmap_new    "$NONIMG_THUMB" _p

# create cache folder for meta files (input path doesn't matter)
get_meta_new -p "$initial_bg_img_origin" _p
unset _p

unset_pixmap_cursor

# ------------------------------------------------------------ #

set -a; source "$APPDIR/sh/dialog_file_cursor_info.sh"; set +a

## All about how we exit gtkdialog
source "$APPDIR/sh/dialog_exit.sh"
export MAIN_DIALOG_SENSITIVE="$RUNTIME_DIR/.sensitive_dialog_main"; echo 1 > "$MAIN_DIALOG_SENSITIVE"
export MAIN_DIALOG_IS_SENSITIVE="cat '$MAIN_DIALOG_SENSITIVE'"
export MAIN_DIALOG_EXIT="$RUNTIME_DIR/.main_dialog_exit"; : > "$MAIN_DIALOG_EXIT" # <file input>
export MAIN_DIALOG_IS_EXIT_HOOK_DEFAULT="[ -s '$MAIN_DIALOG_EXIT' ] && echo 1" # Cf. dialog_exit_hook
export MAIN_DIALOG_IS_EXIT_HOOK_1="grep -qFx hook_1 '$MAIN_DIALOG_EXIT' && echo 1"

## get ready to import some variables from dialog_config
export WALLPAPER_SYNC_CONFIG="$RUNTIME_DIR/.conf_$$"
expose_config_settings

export MAIN_DIALOG="
<window title=\"$i18n_main\" image-name=\"$APPICON\" file-monitor=\"true\">
 <vbox>
  <menubar>
   <menu>
    <menuitem checkbox=\"$("$APPDIR/slideshow" -status-short)\" label=\"$i18n_slideshow\" tooltip-markup=\"$i18n_slideshow_tooltip\">
     <action>if true exec 13>&- 1>&- bash -c 'start_slideshow' &</action>
     <action>if false exec 13>&- 1>&- bash -c 'stop_slideshow' &</action>
    </menuitem>
    <menuitem stock=\"gtk-preferences\" label=\"$i18n_options\">
     <action>bash -c 'exec 13>&- 1>&-; dialog_config' &</action>
    </menuitem>
    <separator></separator>
    <menuitem stock=\"gtk-quit\" label=\"$i18n_quit\" tooltip-markup=\"$i18n_quit_tooltip\">
     <action>bash -c 'dialog_exit_hook menu_quit' &</action>
    </menuitem>
    <label>$i18n_file</label>
   </menu>
   <menu>
    <menuitem stock=\"gtk-about\">
     <action>bash -c 'exec 13>&- 1>&-; dialog_about' &</action>
    </menuitem>
    <menuitem stock=\"gtk-help\" title=\"title\" label=\"$i18n_help_cli\">
     <action>bash -c 'exec 13>&- 1>&-; dialog_help_cli' &</action>
    </menuitem>
    <label>$i18n_help</label>
   </menu>
  </menubar>
   <hbox space-expand=\"true\" space-fill=\"true\" spacing=\"0\">
     ${REM# 6 lines => 260px => ~600px main window height w/ Flat-gray-rounded Gtk2 (default Fatdog64)}
     <chooser width-request=\"600\" height-request=\"260\" space-expand=\"true\" space-fill=\"true\"
      $chooser_file $chooser_mime_types $chooser_patterns>
      $chooser_dir
      <variable>FILE_CURSOR</variable>
      <action when=\"selection-changed\">[ -n \"\$FILE_CURSOR\" ] && exec bash -c swap_pixmap</action>
      <action when=\"selection-changed\">refresh:PIXMAP</action>
      <action when=\"selection-changed\">refresh:STATUSBAR</action>
      <action when=\"selection-changed\">if [ -n \"\$FILE_CURSOR\" ] && [ true = \$LIVE ]; then exec bash -c 'trigger_mode_button true' & fi</action>
     </chooser>
   </hbox>
   <hbox space-expand=\"false\" space-fill=\"false\">
    <hbox space-expand=\"true\" space-fill=\"true\">
      <hbox homogeneous=\"true\" space-expand=\"true\">
     <frame $i18n_subject>
     ${REM# read note N8}
      <eventbox name=\"wallpaper_bg_color\" visible-window=\"true\" border-width=\"0\"
       homogeneous=\"true\" width-request=\"$IMAGE_PIXMAP_WIDTH\" height-request=\"$IMAGE_PIXMAP_HEIGHT\"
       tooltip-text=\"$i18n_click_for_file_info\">
       <pixmap>
        <variable export=\"false\">PIXMAP</variable>
        <input file>$PIXMAP_CURSOR</input>
       </pixmap>
       <action signal=\"button-release-event\">exec 13>&- 1>&- bash -c 'dialog_file_cursor_info' &</action>
      </eventbox>
     </frame>
      </hbox>
    <hbox space-expand=\"false\">
    <frame $i18n_placement>
    <eventbox tooltip-markup=\"$i18n_live_preview_tooltip\">
    <hbox>
       <text><label>$i18n_live_preview</label></text>
     <checkbox label=\"\">
       <variable>LIVE</variable>
       <action>if true exec bash -c 'trigger_mode_button true'</action>
       <action>if true refresh:PIXMAP</action>
       <action>if true refresh:STATUSBAR</action>
     </checkbox>
     </hbox>
     </eventbox>
$(
make_mode_button "Centre"  "$start_bg_mode"
make_mode_button "Tile"    "$start_bg_mode"
make_mode_button "Scale"   "$start_bg_mode"
make_mode_button "Fit"     "$start_bg_mode"
make_mode_button "Stretch" "$start_bg_mode"
make_mode_button "Spread"  "$start_bg_mode"
)
    </frame>
    <frame $i18n_action>
     <button tooltip-markup=\"$i18n_apply_tooltip\">
      <label>$i18n_apply</label>
      <input file stock=\"gtk-apply\"></input>
       <action>exec bash -c 'trigger_mode_button apply' &</action>
      <action>refresh:STATUSBAR</action>
     </button>
     <button tooltip-markup=\"$i18n_undo_tooltip\">
      <input file stock=\"gtk-undo\"></input>
      <label>$i18n_undo</label>
      <action>bash -c 'undo_wallpaper_with_lock' &</action>
     </button>
     <button tooltip-markup=\"$i18n_clear_tooltip\">
      <label>$i18n_clear</label>
      <input file stock=\"gtk-clear\"></input>
      <action>bash -c empty_cache_and_reset_wallpaper</action>
      <action>refresh:PIXMAP</action>
     </button>
     <button tooltip-markup=\"$i18n_edit_tooltip\">
     <label>$i18n_edit</label>
      <input file stock=\"gtk-edit\"></input>
      <action>exec bash -c 'clicked_edit' &</action>
     </button>
     <button height-request=\"30\" tooltip-markup=\"$i18n_view_tooltip\">
      <label>$i18n_view</label>
      <input file>$APPDIR/media/btn_view.png</input>
      <action>exec bash -c 'clicked_view' &</action>
     </button>
     <button tooltip-markup=\"$i18n_filer_tooltip\">
      <label>$i18n_filer</label>
      <input file stock=\"gtk-directory\"></input>
      <action>exec bash -c 'clicked_filer' &</action>
     </button>
    </frame>
    </hbox>
   </hbox>
  </hbox>
  ${REM# undo REMs and set visible to display the status bar}
  <statusbar visible=\"false\" has-resize-grip=\"false\" space-expand=\"false\">
   <default>\"(disabled)\"</default>
   <variable>STATUSBAR</variable>
   ${REM# <input>bash -c status_bar_msg</input>}
   <sensitive>true</sensitive>
  </statusbar>

  ${REM# sync some variables with dialog_config - call expose_config_settings to create the input files}
  <entry visible=\"false\" auto-refresh=\"true\"><variable>BG_COLOR</variable>
   <input file>"$WALLPAPER_SYNC_CONFIG/BG_COLOR"</input>
   <action>bash -c 'empty_cache_and_reset_wallpaper'</action>
   <action>refresh:PIXMAP</action>
  </entry>
  <entry visible=\"false\" auto-refresh=\"true\"><variable>IMAGE_PIXMAP_IMAGE_QUALITY</variable>
  <input file>"$WALLPAPER_SYNC_CONFIG/IMAGE_PIXMAP_IMAGE_QUALITY"</input>
   <action>bash -c 'empty_cache_and_reset_wallpaper'</action>
   <action>refresh:PIXMAP</action>
  </entry>
  <entry visible=\"false\" auto-refresh=\"true\"><variable>IMAGE_WPIMAGE_IMAGE_QUALITY</variable>
  <input file>"$WALLPAPER_SYNC_CONFIG/IMAGE_WPIMAGE_IMAGE_QUALITY"</input>
   <action>bash -c 'empty_cache_and_reset_wallpaper'</action>
   <action>refresh:PIXMAP</action>
  </entry>
  <entry visible=\"false\" auto-refresh=\"true\"><variable>PREFERRED_IMAGE_FORMAT</variable>
  <input file>"$WALLPAPER_SYNC_CONFIG/PREFERRED_IMAGE_FORMAT"</input>
   <action>bash -c 'empty_cache_and_reset_wallpaper'</action>
   <action>refresh:PIXMAP</action>
  </entry>
 </vbox>

 ${REM# file-changed actions do not fire after delete-event}
 <action signal=\"delete-event\">exit:delete_event_is_handled_by_on_signal</action>

 <variable export=\"false\">main_dialog</variable>
 <input file>$MAIN_DIALOG_SENSITIVE</input>
 <input file>$MAIN_DIALOG_EXIT</input>
 <action signal=\"file-changed\" condition=\"command_is_false($MAIN_DIALOG_IS_SENSITIVE)\">disable:main_dialog</action>
 <action signal=\"file-changed\" condition=\"command_is_true($MAIN_DIALOG_IS_SENSITIVE)\">enable:main_dialog</action>

 ${REM# Cf. dialog_exit_hook}
 <action signal=\"file-changed\" condition=\"command_is_true($MAIN_DIALOG_IS_EXIT_HOOK_DEFAULT)\">exit:hook_default</action>
 <action signal=\"file-changed\" condition=\"command_is_true($MAIN_DIALOG_IS_EXIT_HOOK_1)\">exit:hook_1</action>
</window>
"

# ------------------------------------------------------------ #

# Note {N8} - everything you need to ponder before attempting to change the <pixmap> code above.
# Positioning <pixmap> PIXMAP was tricky. The current solution works like a charm in these supported cases:
# (W) PREFERRED_IMAGE_FORMAT==WEBP + optimized_reshape_webp_with_method "pixmap", and
# (J) PREFERRED_IMAGE_FORMAT==JPEG + reshape_image_with_method "pixmap"
# Both methods replace the input alpha channel with $BG_COLOR, and reduce PIXMAP within a $IMAGE_PIXMAP_{WIDTH,HEIGHT} rectangle.
# However Method (W) produces the smallest bounding box of the two while (J)'s bbox is fixed and equals the rectangle.
# Therefore, <pixmap> is not given <size> and <height> attributes otherwise it could distort images in case (W).
# The surrounding <eventbox>'s width-request and size-requests and homogeneous=true attribute ensure that PIXMAP is centered in the rectangle for case (W).
# (J)'s PIXMAP's looks better because its color backdrop fills the rectangle completely while (W)'s may not.
# Set visible-window=true to enable name=wallpaper_bg_color set <eventbox>'s as a color frame around PIXMAP to match the bg color that (W) and (J) bring of their own.
# Great! No?
# The unresolved issue is that name=wallpaper_bg_color fixes the bg color when gtkdialog starts.
# Therefore with (W) a restart is needed to sync the PIXMAP color with $BG_COLOR should the user change bg color preference.
# Alternatively, set PREFERRED_IMAGE_FORMAT==JPEG to avoid this issue altogether - but PIXMAP will load more slowly.

# ------------------------------------------------------------ #

# this possibly long-running coprocess shall not hold lock 13
13<&- 1>&- start_stderr_filter_coprocess # defined in sh/image/image_stderr.sh

#######################################################################
#                     GTKDIALOG/BASH PORTABILITY                      #
#######################################################################

# Make gtkdialog+bash combination portable including to Debian/Ubuntu where
# /bin/sh -> /bin/dash.  In addition to the next four lines, gtkdialog actions
# and conditions that ultimately call exported bash functions must invoke the
# command with "bash -c". See also commit comment 2bbb67ea.
# Note: if the executed command is backgrounded and should not hold lock 13 use:
#   "exec 13>&- bash -c 'command' &"
# (this is the case for many sub-dialogs in this program)

declare -fx > "$RUNTIME_DIR/.func.sh"
echo "unset GTK_MODULES" >> "$RUNTIME_DIR/.func.sh"
((DEBUG)) && cat "$APPDIR/sh/on_bash_env.sh" >> "$RUNTIME_DIR/.func.sh"
export BASH_ENV="$RUNTIME_DIR/.func.sh"

# ------------------------------------------------------------ #
# tsort sh/gtkdialog.sh sh/gui.sh
exec_styled_gtkdialog -c "$@" > "$RUNTIME_DIR/.stdout" &
wait $!

# refresh configuration in case the user ran dialog_config
source "$USRDIR/preferences"
##get_var_value_from_file "$RUNTIME_DIR/.stdout" PREFERRED_IMAGE_FORMAT PREFERRED_IMAGE_FORMAT
#((DEBUG)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO" PREFERRED_IMAGE_FORMAT >&2
# ------------------------------------------------------------ #

if [ "true" = "$SHOW_EXIT_DIALOG" ]; then
  dialog_exit mode_img_origin export_to_dir
  ((DEBUG)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO" mode_img_origin >&2

  if [ -s "${mode_img_origin#*:}" ]; then
    impress_wallpaper "$mode_img_origin"
    wait_until_in_progress_impression_is_done
  fi

  if [ -d "$export_to_dir" ]; then
    get_apprun_wallpaper_state wp_mode wp_img wp_img_origin
    ((DEBUG)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO" wp_mode wp_img wp_img_origin >&2

    # corner case: when rox's backdrop is located outside the cache, e.g.
    # Fatdog first boot (test with QEMU runsfs.sh)
    if ! has_cached_path "$wp_img"; then
      # with LIVE=non-null to force a state update
      LIVE="non-null" impress_wallpaper "$wp_mode:$wp_img_origin"
      wait_until_in_progress_impression_is_done
      get_apprun_wallpaper_state wp_mode wp_img wp_img_origin
      ((DEBUG)) && dprint_varname "${BASH_SOURCE##*/}:$LINENO" wp_mode wp_img wp_img_origin >&2
    fi

    get_cached_basename "$wp_img" basename
    cp --backup=t "$wp_img" "$export_to_dir/${basename%.*}.${PREFERRED_IMAGE_FORMAT,,}"
  fi
fi

# $PIXMAP_CURSOR isn't needed when $MAIN_DIALOG is over
unset_pixmap_cursor

# on to exit via on_signal

