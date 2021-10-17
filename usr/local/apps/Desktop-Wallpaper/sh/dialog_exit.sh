# This BASH file is sourced not run
((DEBUG)) && export __loaded_dialog_exit=$(($__loaded_dialog_exit +1)) && echo >&2 "dialog_exit.sh{$__loaded_dialog_exit}"

dialog_exit_hook () { # $1-gtk_dialog_origin_widget
# Generalized exit hook for gtkdialog. In lieu of the of the commonplace XML
# exit idiom: `<action>EXIT:{quit,close, ...}</action>` $MAIN_DIALOG runs this
# function with:
#   <action>bash -c 'dialog_exit_hook menu_quit # or button_close ...'</action>
# Note that closing the window from the window title bar or window menu
# will _not_ invoke this function - Cf. "delete_event_is_handled_by_on_signal".

# ----------------------------------------------------
# At the moment AppRun makes no real use of this function.
# The code below is a template for future development.
# ----------------------------------------------------

	local origin_widget="$1" exit_action="hook_default"
	((DEBUG>1)) && dprint_varname "$FUNCNAME" origin_widget >&2

	# Take action based on which gtkdialog widget originated this dialog
	case "$origin_widget" in
		"your-widget-here" ) # "menu_quit", "button_close", ...

			# Here you can perform actions that take place before exiting the main window.
			# For instance, you could display a modal dialog:
			: echo 0 > "$MAIN_DIALOG_SENSITIVE" # desensitize the main window to show your modal dialog
			: dialog_ok_cancel ...
			# and go back to the main window by unsetting
			: unset exit_action

			# or exit gtkdialog with a given label, such as "hook_1" ... and so on
			# (if you need more exit labels define them in gui.sh - Cf. "HOOK_1" and "hook_1" there)
			: exit_action="hook_1" # Cf. trap handler function on_signal
			;;
	esac

	# a non-empty $exit_action makes gtkdialog exit
	printf "%s" "$exit_action" > "$MAIN_DIALOG_EXIT"
	((DEBUG>1)) && dprint_varname "$FUNCNAME" exit_action >&2

	echo 1 > "$MAIN_DIALOG_SENSITIVE"
}
export -f dialog_exit_hook

# ------------------------------------------------------------ #

dialog_exit () { # $1-varname_mode_img_origin $2-varname_export_to
# Offer to stop a running slideshow.
# Display pixmaps of significant¹ wallpapers to choose their EXISTING origin from.
# Return "" in variable $1 if no choice is made to change the status quo.
# Return export path in variable $2 for optional wallpaper export action.
# ___
# [¹] The applied wallpaper, the last unapplied preview, the wallpaper when the
# app started, and the last slideshow slide, if any of these exist, and without
# duplicates.

	local -n varname_mode_img="$1"; varname_mode_img=
	local -n varname_export_to_dir="$2"; varname_export_to_dir=
	local slideshow_is_running
	local pixs; local -i npixs=0
	local wp_mode wp_img wp_img_origin wp_pixmap
	local staged_mode staged_img staged_img_origin staged_pixmap
	local initial_mode initial_img initial_pixmap initial_pixmap_origin
	local slide_mode slide_img slide_img_origin slide_pixmap
	local dlg EXIT chosen_img_origin

	## disable wallpaper changes temporarily

	"$APPDIR/slideshow" -status-short > /dev/null
	if (( slideshow_is_running=!$? )); then
		"$APPDIR/slideshow" -hold
		# let in-progress impression finish, if any
		wait_until_in_progress_impression_is_done
	fi

	## prepare pixmaps

	# applied wallpaper
	get_last_commit wp_mode wp_img wp_img_origin
	[ -s "$wp_img_origin" ] || wp_img_origin=
	get_pixmap_new "$wp_img_origin" wp_pixmap

	# last uncommitted preview
	get_staged_change staged_mode staged_img staged_img_origin
	[ -s "$staged_img_origin" ] || staged_img_origin=
	get_pixmap_new "$staged_img_origin" staged_pixmap

	# last slideshow slide
	get_slideshow_state slide_mode slide_img slide_img_origin __
	[ -s "$slideshow_img_origin" ] || slideshow_img_origin=
	get_pixmap_new "$slide_img_origin" slide_pixmap

	# starting wallpaper
	get_restore_point initial_mode initial_img initial_img_origin
	has_cached_path "$initial_img" || initial_img_origin="$initial_img"
	[ -s "$initial_img_origin" ] || initial_img_origin=
	get_pixmap_new "$initial_img_origin" initial_pixmap

	((DEBUG>1)) && dprint_varname "$FUNCNAME:$LINENO" wp_mode wp_img wp_img_origin wp_pixmap >&2
	((DEBUG>1)) && dprint_varname "$FUNCNAME:$LINENO" staged_mode staged_img staged_img_origin staged_pixmap >&2
	((DEBUG>1)) && dprint_varname "$FUNCNAME:$LINENO" slide_mode slide_img slide_img_origin slide_pixmap >&2
	((DEBUG>1)) && dprint_varname "$FUNCNAME:$LINENO" initial_mode initial_img initial_pixmap >&2

	## select without duplicates
	local seen
	not_seen() { [[ -e "$1" && $'\n'"$seen"$'\n' != *$'\n'"$1"$'\n'* ]] && seen+=$'\n'"$1"; }
	if not_seen "$wp_img_origin"; then
		npixs+=1
		dlg_exit_add_pixmap_xml pixs "$wp_img_origin" "$wp_mode" "$wp_pixmap" "$i18n_dlg_exit_wp" "$npixs"
	fi
	if not_seen "$staged_img_origin"; then
		npixs+=1
		dlg_exit_add_pixmap_xml pixs "$staged_img_origin" "$staged_mode" "$staged_pixmap" "$i18n_dlg_exit_staged" "$npixs"
	fi
	if not_seen "$slide_img_origin"; then
		npixs+=1
		dlg_exit_add_pixmap_xml pixs "$slide_img_origin" "$slide_mode" "$slide_pixmap" "$i18n_dlg_exit_slide" "$npixs"
	fi
	if not_seen "$initial_img_origin"; then
		npixs+=1
		dlg_exit_add_pixmap_xml pixs "$initial_img_origin" "$initial_mode" "$initial_pixmap" "$i18n_dlg_exit_initial" "$npixs"
	fi
	(( npixs > 1 )) || unset pixs # at least two different pixmaps needed

	## create dialog

	dlg="
	<window title=\"$i18n_dlg_exit_title\" image-name=\"$APPICON\">
	<vbox>
	<frame>"
	if ((slideshow_is_running)); then
		# checkbox "stop the slideshow?"
		dlg+="
		<checkbox label=\"$i18n_dlg_exit_active_slideshow\" tooltip-text=\"$i18n_dlg_exit_active_slideshow_tooltip\">
		<variable>CHK_STOP_SLIDESHOW</variable>
		</checkbox>"
	fi
	if :; then
		# checkbox "show this dialog next time?"
	dlg+="
		<checkbox label=\"$i18n_dlg_exit_show_exit_dialog\" tooltip-text=\"$i18n_dlg_exit_show_exit_dialog_tooltip\">
		<variable>CHK_SHOW_EXIT_DIALOG</variable>
		<default>${SHOW_EXIT_DIALOG:-true}</default>
		</checkbox>"

		# export current wallpaper to ...
	dlg+="
		<checkbox label=\"$i18n_dlg_exit_export_to_chk\" tooltip-text=\"$i18n_dlg_exit_export_to_chk_tooltip\">
		<variable>CHK_EXPORT_TO_DIR</variable>
		</checkbox>

		<entry accept=\"directory\" \
		tooltip-text=\"$i18n_dlg_exit_export_to_chk_tooltip\" \
		primary-icon-stock=\"gtk-open\" primary-icon-activatable=\"true\" \
		primary-icon-tooltip-text=\"$i18n_dlg_exit_export_to_btn_tooltip\">
		<action signal=\"primary-icon-release\">fileselect:EXPORT_TO_DIR</action>
		<default>\"${TMPDIR:-/tmp}\"</default>
		<variable>EXPORT_TO_DIR</variable>
		</entry>"

	dlg+="
	</frame>"
	fi
	if ((npixs > 1)); then
		# pixmap gallery: click pixmap to exit
		dlg+="
		<hbox spacing=\"0\">
		<text xalign=\"0.5\" width-request=\"500\" use-markup=\"true\" label=\"$i18n_dlg_exit_pixs_intro\"></text>
		</hbox>
		<hbox spacing=\"10\">$pixs</hbox>"
	else
		# ok/cancel
		dlg+="
		<hbox homogeneous=\"true\">
		<hbox spacing=\"20\"><button ok></button><button cancel></button></hbox>
		</hbox>"
	fi
	dlg+="
	</vbox>
	</window>"

	## show dialog
	unset CHK_STOP_SLIDESHOW CHK_SHOW_EXIT_DIALOG EXPORT_TO_DIR
	eval $(MAIN_DIALOG="$dlg" exec_styled_gtkdialog -c --space-expand=true --space-fill=true)

	## save configuration
	echo  "SHOW_EXIT_DIALOG=\"$CHK_SHOW_EXIT_DIALOG\"" |
		replace_config_settings

	## stop/release the slideshow
	if (( slideshow_is_running )); then
		if [ "true" = "$CHK_STOP_SLIDESHOW" ]; then
			"$APPDIR/slideshow" -stop
			slideshow_is_running=0
		else
			# release slideshow in 10 seconds without keeping the single
			# AppRun instance lock while sleeping
			(exec 13<&-; sleep 10; "$APPDIR/slideshow" -release) &
		fi
	fi
	(( slideshow_is_running )) || reset_slideshow_state

	## return chosen origin
	if [[ "$EXIT" == "link_origin="* ]]; then
		EXIT="${EXIT#*=}"
		chosen_img_origin="$(realpath "${EXIT#*:}")"
		varname_mode_img="${EXIT%%:*}:$chosen_img_origin"
		((DEBUG>1)) && dprint "$FUNCNAME" "varname_mode_img($varname_mode_img)" >&2
	fi

	## return export path
	if [ "$CHK_EXPORT_TO_DIR" = "true" ]; then
		varname_export_to_dir="$EXPORT_TO_DIR"
	fi
}

dlg_exit_add_pixmap_xml () { # $1-varname_xml $2-img_origin $3-mode $4-img_pixmap $5-label $6-id
# $3-img must be a GtkImage supported format.

	local -n varname_xml="$1"; local img_origin="$2" mode="$3" img="$4" lbl="$5" id="$6"

	# contortions to avoid breaking gtkdialog
	local entry_default="${img_origin//\</}"
	local tooltip_text="${img_origin//\"/}"
	local ln_img="$RUNTIME_DIR/.ln_exit_img_${id}"
	local ln_img_origin="$RUNTIME_DIR/.ln_exit_img_origin_${id}"
	ln -sfT "$img" "$ln_img" &&
	ln -sfT "$img_origin" "$ln_img_origin" &&

	varname_xml+="
	<frame>
	<eventbox name=\"wallpaper_bg_color\" visible-window=\"true\" above-child=\"true\"
	tooltip-text=\"$tooltip_text\"
	space-expand=\"true\" space-fill=\"true\"
	width-request=\"$((IMAGE_PIXMAP_WIDTH /2))\" height-request=\"$((IMAGE_PIXMAP_HEIGHT /2))\">
	<pixmap><input file>$ln_img</input></pixmap>
	<action signal=\"button-release-event\">exit:link_origin=$mode:$ln_img_origin</action>
	</eventbox>

	<vbox width-request=\"200\" space-expand=\"false\" space-fill=\"false\">
	<text xalign=\"0.5\" yalign=\"1\" use-markup=\"true\" label=\"$lbl\"></text>
	<entry xalign=\"0.5\" editable=\"false\" has-frame=\"false\" tooltip-text=\"$tooltip_text\">
	<default>${entry_default##*/}</default>
	</entry>
	</vbox>
	</frame>
	"
}

