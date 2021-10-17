# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_dialog_config=$(($__loaded_dialog_config +1)) && echo >&2 "dialog_config.sh{$__loaded_dialog_config}"

# tsort func:die sh/dialog_config.sh
# tsort sh/gtkdialog.sh sh/dialog_config.sh
# tsort func:get_reshaping_output_formats sh/dialog_config.sh

dialog_config () {
  local entry_width="350" label_width="250" # pixels
  export CONFIG_DIALOG_SENSITIVE="$RUNTIME_DIR/.sensitive_dialog_config"
  export CONFIG_DIALOG_IS_SENSITIVE="cat '$CONFIG_DIALOG_SENSITIVE'"

  local preferred_image_formats
  get_reshaping_output_formats preferred_image_formats
  printf -v preferred_image_formats "<item>%s</item>\n" $preferred_image_formats

  # Run only one dialog at the time
{ # BEGIN LOCK
  flock -n 5 || die "$i18n_error_exclusive_lock (ELOCK) (5)"

  source "$CONFIG_FILE" || return 1
  local bg_color="#${BG_COLOR//\//}"

  [ -e "$MAIN_DIALOG_SENSITIVE" ] && echo "false" > "$MAIN_DIALOG_SENSITIVE"
  echo "true"  > "$CONFIG_DIALOG_SENSITIVE"

  printf "$bg_color"  > "$RUNTIME_DIR/.BG_COLOR"

  export desktop_wallpaper_configuration="
<window title=\"$i18n_configuration_window\" image-name=\"$APPICON\" window_position=\"2\" file-monitor=\"true\">
 <vbox border-width=\"10\">
  <frame $i18n_conf_slideshow>
  <hbox>

   <hbox name=\"i18n_conf_slideshow_slide_dir\" space-expand=\"true\" space-fill=\"true\">
    <entry width-request=\"$entry_width\" \
      accept=\"directory\" tooltip-text=\"$i18n_conf_slideshow_slide_dir_tooltip\" \
      fs-folder=\"$SLIDEDIR\" \
      primary-icon-stock=\"gtk-open\" primary-icon-activatable=\"true\" primary-icon-tooltip-text=\"$i18n_conf_slideshow_slide_dir_tooltip\">
     <action signal=\"primary-icon-release\">fileselect:SLIDEDIR</action>
     <default>\"$SLIDEDIR\"</default>
     <variable>SLIDEDIR</variable>
    </entry>
   </hbox>

   <hbox width-request=\"$label_width\" space-expand=\"true\" space-fill=\"false\">
   <hbox>
    <text label=\"${i18n_conf_slideshow_shuffle#*;}\" tooltip-text=\"$i18n_conf_slideshow_shuffle_tooltip\"></text>
    <checkbox tooltip-text=\"$i18n_conf_slideshow_shuffle_tooltip\" label=\" \">
     <variable>RANDOM_IMAGE</variable>
     <input>echo $RANDOM_IMAGE</input>
    </checkbox>
   </hbox>

   <hbox>
    <text use-markup=\"true\" label=\"$i18n_conf_slideshow_interval\" tooltip-text=\"$i18n_conf_slideshow_interval_tooltip\"></text>
    <spinbutton width-chars=\"4\" xalign=\"0\" tooltip-text=\"$i18n_conf_slideshow_interval_tooltip\" range-min=\"1\" range-max=\"86400\" range-value=\"$INT\">
     <variable>INT</variable>
    </spinbutton>
   </hbox>
   </hbox>

  </hbox>
  </frame>
  <frame $i18n_conf_programs>
   <hbox space-expand=\"true\" space-fill=\"true\">
    <entry width-request=\"$entry_width\" \
      accept=\"file\" tooltip-text=\"$i18n_program_chooser_entry_hint\" \
      fs-folder=\"$HOME\" \
      primary-icon-stock=\"gtk-open\" primary-icon-activatable=\"true\" primary-icon-tooltip-text=\"$i18n_program_chooser_entry_hint\">
     <action signal=\"primary-icon-release\">fileselect:SHUFFLER</action>
     <variable>SHUFFLER</variable>
     <default>\"$SHUFFLER\"</default>
    </entry>
    <text xalign=\"0\" width-request=\"$label_width\" label=\"$i18n_conf_shuffler\"></text>
   </hbox>


   <hbox space-expand=\"true\" space-fill=\"true\">
    <entry width-request=\"$entry_width\" \
      accept=\"file\" tooltip-text=\"$i18n_program_chooser_entry_hint\" \
      fs-folder=\"$HOME\" \
      primary-icon-stock=\"gtk-open\" primary-icon-activatable=\"true\" primary-icon-tooltip-text=\"$i18n_program_chooser_entry_hint\">
     <action signal=\"primary-icon-release\">fileselect:FILER</action>
     <variable>FILER</variable>
     <default>\"$FILER\"</default>
    </entry>
    <text xalign=\"0\" width-request=\"$label_width\" label=\"$i18n_conf_filemanager\"></text>
   </hbox>

   <hbox space-expand=\"true\" space-fill=\"true\">
    <entry width-request=\"$entry_width\" \
      accept=\"file\" tooltip-text=\"$i18n_program_chooser_entry_hint\" \
      fs-folder=\"$HOME\" \
      primary-icon-stock=\"gtk-open\" primary-icon-activatable=\"true\" primary-icon-tooltip-text=\"$i18n_program_chooser_entry_hint\">
     <action signal=\"primary-icon-release\">fileselect:IMGEDITOR</action>
     <variable>IMGEDITOR</variable>
     <default>\"$IMGEDITOR\"</default>
    </entry>
    <text xalign=\"0\" width-request=\"$label_width\" label=\"$i18n_conf_img_editor\"></text>
   </hbox>

   <hbox space-expand=\"true\" space-fill=\"true\">
    <entry width-request=\"$entry_width\" \
      accept=\"file\" tooltip-text=\"$i18n_program_chooser_entry_hint\" \
      fs-folder=\"$HOME\" \
      primary-icon-stock=\"gtk-open\" primary-icon-activatable=\"true\" primary-icon-tooltip-text=\"$i18n_program_chooser_entry_hint\">
     <action signal=\"primary-icon-release\">fileselect:VIEWER</action>
     <variable>VIEWER</variable>
     <default>\"$VIEWER\"</default>
    </entry>
    <text xalign=\"0\" width-request=\"$label_width\" label=\"$i18n_conf_img_viewer\"></text>
   </hbox>

  </frame>
  <frame $i18n_conf_images>
   <hbox space-expand=\"true\" space-fill=\"true\">
   <comboboxtext width-request=\"$entry_width\" \
     tooltip-markup=\"$i18n_conf_preferred_image_format_tooltip $i18n_config_preferred_format_JPEG $i18n_config_preferred_format_WEBP\">
     <variable>PREFERRED_IMAGE_FORMAT</variable>
     <default>\"$PREFERRED_IMAGE_FORMAT\"</default>
     $preferred_image_formats
    </comboboxtext>
    <text xalign=\"0\" width-request=\"$label_width\" label=\"$i18n_conf_preferred_image_format\"></text>
   </hbox>

   <hbox space-expand=\"true\" space-fill=\"true\">
    <entry width-request=\"$entry_width\" \
      tooltip-markup=\"$i18n_conf_image_quality_tooltip\">
     <variable>IMAGE_PIXMAP_IMAGE_QUALITY</variable>
     <default>\"$IMAGE_PIXMAP_IMAGE_QUALITY\"</default>
    </entry>
    <text xalign=\"0\" width-request=\"$label_width\" label=\"$i18n_conf_subject_image_quality\"></text>
   </hbox>

   <hbox space-expand=\"true\" space-fill=\"true\">
    <entry width-request=\"$entry_width\" \
      tooltip-markup=\"$i18n_conf_image_quality_tooltip\">
     <variable>IMAGE_WPIMAGE_IMAGE_QUALITY</variable>
     <default>\"$IMAGE_WPIMAGE_IMAGE_QUALITY\"</default>
    </entry>
    <text xalign=\"0\" width-request=\"$label_width\" label=\"$i18n_conf_wallpaper_image_quality\"></text>
   </hbox>

   <hbox space-expand=\"true\" space-fill=\"true\">
      <colorbutton width-request=\"$entry_width\" auto-refresh=\"true\">
       <input file>$RUNTIME_DIR/.BG_COLOR</input>
       <output file>$RUNTIME_DIR/.BG_COLOR</output>
       <variable>BG_COLOR</variable>
       <action>save:BG_COLOR</action>
       <action>echo true > \"$CONFIG_DIALOG_SENSITIVE\"</action>
      </colorbutton>

    <text xalign=\"0\" width-request=\"$label_width\" label=\"$i18n_conf_bg_color\"></text>

     <text visible=\"false\" auto-refresh=\"true\">
      <input file>$RUNTIME_DIR/.BG_COLOR</input>
     </text>
   </hbox>

  </frame>
  <frame $i18n_conf_interface>

   <checkbox label=\"$i18n_conf_show_exit_dialog\">
    <variable>SHOW_EXIT_DIALOG</variable>
    <default>$SHOW_EXIT_DIALOG</default>
   </checkbox>
  </frame>

  <hbox homogenuous=\"true\">
   <hbox padding=\"10\" space-expand=\"true\">
    <button ok></button>
    <button cancel></button>
     <button>
      <label>\"$i18n_help\"</label>
      <input file stock=\"gtk-help\"></input>
      <action>bash -c 'dialog_help_cli' &</action>
     </button>
   </hbox>
  </hbox>
 </vbox>
 <variable export=\"false\">config_dialog</variable>
 <input file>$CONFIG_DIALOG_SENSITIVE</input>
 <action signal=\"file-changed\" condition=\"command_is_false($CONFIG_DIALOG_IS_SENSITIVE)\">disable:config_dialog</action>
 <action signal=\"file-changed\" condition=\"command_is_true($CONFIG_DIALOG_IS_SENSITIVE)\">enable:config_dialog</action>

</window>
"
# ------------------------------------------------------------ #

  exec_styled_gtkdialog -p desktop_wallpaper_configuration |
    replace_config_settings &&
    expose_config_settings

  [ -e "$MAIN_DIALOG_SENSITIVE" ] && echo "true" > "$MAIN_DIALOG_SENSITIVE"
  rm -f "$RUNTIME_DIR/.BG_COLOR" "$CONFIG_DIALOG_SENSITIVE"

} 5< "$(realpath "$CONFIG_FILE")"; exec 5<&- # END LOCK
}

# ------------------------------------------------------------ #

dialog_only_rox_can_change_setting () {
  echo false > "$CONFIG_DIALOG_SENSITIVE"
  dialog_ok_cancel "$i18n_conf_only_rox_can_change_setting $i18n_conf_rox_how_change_bg_color $i18n_restart_when_done" "gtk-ok~~~no-cancel"
  echo true > "$CONFIG_DIALOG_SENSITIVE"
}

# ------------------------------------------------------------ #

expose_config_settings () {
# For each configuration setting NAME=VALUE write VALUE to file
# $WALLPAPER_SYNC_CONFIG/NAME. This function is used to expose settings to
# gtkdialog variables.

  [ -n "$WALLPAPER_SYNC_CONFIG" ] || return 1
  local s p

  if mkdir -p "$WALLPAPER_SYNC_CONFIG"; then
    while IFS= read s; do # not -r !
      [[ "$s" =~ ^[[:alnum:]_]+"=".* ]] || continue
      printf "%s\n" "${s#*=}" > "$WALLPAPER_SYNC_CONFIG/${s%%=*}"
    done < "$CONFIG_FILE"
  fi
}

# ------------------------------------------------------------ #

replace_config_settings () { # [$1-ignore_regex [$2-abort_regex]]
# Rewrite $CONFIG_FILE incorporating changes from stdin.  Format stdin
# like gtkdialog would, e.g., varname="value", including double quotes, which
# will be trimmed on output.
# Lines matching regex $1 will be ignored. $1 takes precedence over $2.  The
# first line matching regex $2 will cause immediate return leaving
# $CONFIG_FILE unchanged.
# Automatic value edits:
# - HTML hex color to internal color: "#f8ffd8" => "f8/ff/d8"

  local ignore='EXIT="OK"' abort='EXIT=' s
  local -a a z
  local -i na nz i
  local -A m

  ## filter stdin a => z
  mapfile -t a
  na=${#a[*]}
  for (( i = 0; i < na; i++ )); do
    s="${a[i]}"
    if  [[  "$s" =~ ^$ignore ]]; then continue
    elif [[ "$s" =~ ^$abort  ]]; then return
    elif [[ "$s" =~ ^[[:alnum:]_]+=\" ]]; then
      s="${s/\"}"; s="${s%\"}" # trim quotes
      if [[ "$s" =~ ([^=]+)'=#'([[:xdigit:]]{6,6}) ]]; then # HTML hex color
       s="${BASH_REMATCH[1]}=${BASH_REMATCH[2]:0:2}/${BASH_REMATCH[2]:2:2}/${BASH_REMATCH[2]:4:2}"
      fi
      z+=( "$s" )
    fi
  done

  ## merge filtered z into configuration file
  nz=${#z[*]}
  if ((nz)); then
    while IFS= read s; do # not -r !
      m["${s%%=*}"]="${s#*=}"
    done < "$CONFIG_FILE"

    for (( i = 0; i < nz; i++ )); do
      s="${z[i]}"
      m["${s%%=*}"]="${s#*=}"
    done

    ## output merged
    for s in "${!m[@]}"; do
      printf "%s=%q\n" "$s" "${m[$s]}"
    done > "$CONFIG_FILE"
  fi
}

