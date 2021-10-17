# This POSIX shell file is sourced not run
[ "${DEBUG:-0}" -gt 0 ] && export __loaded_dialog_file_cursor_info=$(($__loaded_dialog_file_cursor_info +1)) && echo >&2 "dialog_file_cursor_info.sh{$__loaded_dialog_file_cursor_info}"

dialog_file_cursor_info () {
export desktop_wallpaper_file_info="
<window title=\"$i18n_file_info_window\" icon-name=\"gtk-info\" window_position=\"2\">
 <vbox>
  <vbox scrollable=\"true\" height=\"300\" width=\"640\">
  <eventbox name=\"text_box_light\">
  <vbox>
   <text wrap=\"false\" xalign=\"0\" selectable=\"true\" use-markup=\"true\" can-focus=\"false\">
    <input>bash -c 'file_cursor_info'</input>
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
  exec_styled_gtkdialog -p desktop_wallpaper_file_info
}

