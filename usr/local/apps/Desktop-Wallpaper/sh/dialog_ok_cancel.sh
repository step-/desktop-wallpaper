# This POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && export __loaded_dialog_ok_cancel=$(($__loaded_dialog_ok_cancel +1)) && echo >&2 "dialog_ok_cancel.sh{$__loaded_dialog_ok_cancel}"

# tsort sh/i18n_table.sh sh/dialog_ok_cancel.sh
# tsort sh/dialog_ok_cancel.sh func:die

dialog_ok_cancel () { # ['use-markup'] $1-text [$2-button_labels]
# Two-button question dialog
# btn_labels ::= gtk2_stock_button1'~~~'gtk2_stock_button2
#              | button1_label'~~~'( 'no-cancel' | button2_label )
# 'no-cancel' hides button2
# Fallback buttons: btn1 = 'gtk-ok' <<< focused ;  btn2 = 'gtk-cancel'
# Accept (return 0): Enter key and button_1
# Cancel (return 1): ESC key, button_2, and closing the window
  local use_markup text btn_labels button2
  [ "use-markup" = "$1" ] && use_markup=' use-markup="true"' && shift
  text="$1" btn_labels="$2"
  local btn1_lbl=" use-stock=\"true\" label=\"gtk-ok\">"
  local btn2_lbl=" use-stock=\"true\" label=\"gtk-cancel\">"
  case "$btn_labels" in
    "gtk-"*"~~~gtk-"*|"gtk-"*"~~~no-cancel") # gtk2_stock_button{1,2}
      btn1_lbl=" use-stock=\"true\" label=\"${btn_labels%~~~*}\">"
      btn2_lbl=" use-stock=\"true\" label=\"${btn_labels#*~~~}\">"
      ;;
    *~~~*) # button{1,2}_label
      btn1_lbl="><label>\"   ${btn_labels%~~~*}   \"</label>"
      btn2_lbl="><label>\"   ${btn_labels#*~~~}   \"</label>"
      ;;
  esac
  case "$btn_labels" in
    *no-cancel*) : ;;
    *) button2='
   <button width-request="200"'"$btn2_lbl"'
    <action>EXIT:cancel</action>
   </button>'
  esac

  $GTKDIALOG -cs << EOF | grep -qFm1 'EXIT="ok"'
<window title="$i18n_main" image-name="$APPICON">
 <vbox>
  <vbox border-width="10">
   <text$use_markup>
    <label>"$text"</label>
   </text>
  </vbox>
  <hseparator></hseparator>
  <hbox homogeneous="true" spacing="10" border-width="5">
   <button can-default="true" has-default="true" width-request="200"$btn1_lbl
    <action>EXIT:ok</action>
   </button>
   $button2
  </hbox>
 </vbox>
 <action signal="key-press-event" condition="command_is_true([ \"\$KEY_RAW\" = '0x9' ] && echo 1)">EXIT:escape</action>
</window>
EOF
}

die () { # [use-markup] $1-message [$2-exit_code]
  local use_markup
  [ "use-markup" = "$1" ] && use_markup="$1" && shift
  echo "$i18n_main: $1" >&2
  dialog_ok_cancel $use_markup "$1" "gtk-ok~~~no-cancel"
  exit ${2:-1}
}
