# This POSIX shell file is sourced not run
[ "${DEBUG:-0}" -gt 0 ] && export __loaded_dialog_help_cli=$(($__loaded_dialog_help_cli +1)) && echo >&2 "dialog_help_cli.sh{$__loaded_dialog_help_cli}"

dialog_help_cli() {
export desktop_wallpaper_help="
<window title=\"$i18n_help_cli_window\" icon-name=\"gtk-help\" window_position=\"2\">
<vbox>
  <vbox border-width=\"5\" scrollable=\"true\" height=\"450\" width=\"640\">
   <eventbox name=\"text_box_light\">
    <vbox>
  <text use_markup=\"true\">
   <label>\"<b>$APP_NAME_VERSION</b>\"</label>
  </text>
   <text wrap=\"false\" xalign=\"0\" selectable=\"true\" use-markup=\"true\" can-focus=\"false\">
    <input>'$APPDIR/cli' --help | awk -f '$APPDIR/script/help_text_to_pango_markup.awk'</input>
   </text>
 </vbox>
   </eventbox>
  </vbox>
  <hbox homogeneous=\"true\">
    <button ok></button>
  </hbox>
</vbox>
</window>
"
  exec_styled_gtkdialog -p desktop_wallpaper_help
}

