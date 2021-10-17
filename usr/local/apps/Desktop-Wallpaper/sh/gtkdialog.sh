# This POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && export __loaded_gtkdialog=$(($__loaded_gtkdialog +1)) && echo >&2 "gtkdialog.sh{$__loaded_gtkdialog}"

exec_styled_gtkdialog () { # $@-args
# usage: exec_styled_gtkdialog args... & wait $!
# Exec gtkdialog with custom GTK+ 2 and GTK+ 3 styles.

	case "$GTKDIALOG" in
	*"gtk3"* ) set -- "$@" --styles "$RUNTIME_DIR/.gtk.css" ;;
	* ) export GTK2_RC_FILES="$RUNTIME_DIR/.gtkrc-2.0:$HOME/.gtkrc-2.0" ;;
	esac
	exec $GTKDIALOG "$@"
}

# ------------------------------------------------------------ #

# tsort var:BG_COLOR sh/gtkdialog.sh

echo > "$RUNTIME_DIR/.gtkrc-2.0" '
style "BG_COLOR" { bg[NORMAL] = "'"#${BG_COLOR//\//}"'" }
widget "*wallpaper_bg_color" style "BG_COLOR"
style "textBoxLight" {
	bg[NORMAL] = "#ffffff"
	fg[NORMAL] = "#000000"
}
widget "*text_box_light" style "textBoxLight"
style "textBoxDark" {
	bg[NORMAL] = "#000000"
	fg[NORMAL] = "#ffffff"
}
widget "*text_box_dark" style "textBoxDark"
'
echo > "$RUNTIME_DIR/.gtk.css" '
#wallpaper_bg_color { background-color: '"#${BG_COLOR//\//}"'; }
#text_box_light {
	background-color: #ffffff;
	color: #000000;
}
#text_box_dark {
	background-color: #000000;
	color: #ffffff;
}
/* override theme */
.frame { border-style: none; } /* don`t frame boxes -- does not impact gtkdialog`s frame */
scrollbar.vertical slider { min-height: 0; } /* don`t make scrollable window taller than necessary */
'

