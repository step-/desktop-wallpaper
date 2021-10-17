# This POSIX shell file is sourced not run
[ "${DEBUG:-0}" -gt 0 ] && export __loaded_functions=$(($__loaded_functions +1)) && echo >&2 "functions.sh{$__loaded_functions}"

dialog_about() {
  local homepage="https://github.com/step-/desktop-wallpaper"
  export desktop_wallpaper_about="
<window title=\"$i18n_about_window\" image-name=\"$APPICON\" window_position=\"2\">
 <vbox margin=\"10\">
 <eventbox name=\"text_box_light\">
 <vbox>
  <text xalign=\"0.5\" use_markup=\"true\"><label>\"
   <b>$APP_NAME_VERSION</b>
   \"</label>
  </text>
  <vbox margin=\"10\">
   <text>
    <label>\"$i18n_about_text\"</label>
   </text>
  </vbox>
  <vbox margin=\"10\">
   <text use_markup=\"true\">
    <label>\"<u><span fgcolor='blue'>$homepage</span></u>\"</label>
   </text>
  </vbox>
 </vbox>
 </eventbox>
  <hbox homogeneous=\"true\">
   <button ok></button>
  </hbox>
 </vbox>
</window>
"
  exec_styled_gtkdialog -p desktop_wallpaper_about
}

