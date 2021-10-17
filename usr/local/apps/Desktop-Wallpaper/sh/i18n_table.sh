# This POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && export __loaded_i18n_table=$(($__loaded_i18n_table +1)) && echo >&2 "i18n_table.sh{$__loaded_i18n_table}"

# See file ../LICENSE for license and version information.

# Desktop Wallpaper translation file
# language en_GB
# i18n_table template version: 20210827 for POSIX shell.

# --- Early init ----------------------------------------------------------{{{1

# --- Init localization i18n ----------------------------------------------{{{1

export TEXTDOMAIN=fatdog OUTPUT_CHARSET=UTF-8
# . gettext.sh

# --- Translation table i18n ----------------------------------------------{{{1

# Notes for translators
# ---------------------
# To create a pot file for this script use xgettext.sh[1] instead of xgettext.
# xgettext.sh augments xgettext with the ability to extract MSGIDs from calls
# to 'gettext -es'.
# [1] https://github.com/step-/i18n-table
#
# A. Never use \n **inside** your MSGSTR. For yad and gtkdialog replace \n with \r.
# B. However, always **end** your MSGSTR with \n.
# C. Replace trailing spaces (U+0020) with no-break spaces (U+00A0).

i18n_table() {
# Cf. xgettext.sh usage:
# [c1] comment lines found inside this function are reproduced with prefix "#."
# [c2] variable names are reproduced with prefix "#." above their MSGIDs.

local unicode_1F500="🔀" # U+1F500 TWISTED RIGHTWARDS ARROWS (not Dejavu Mono)
local unicode_21BB="↻" # U+21BB CLOCKWISE OPEN CIRCLE ARROW

	{

# RADIO BUTTONS
read i18n_centre
read i18n_tile
read i18n_scale
read i18n_fit
read i18n_stretch
read i18n_spread
# tooltips
read i18n_centre_tooltip
read i18n_tile_tooltip
read i18n_scale_tooltip
read i18n_fit_tooltip
read i18n_spread_tooltip
read i18n_stretch_tooltip

# MAIN WINDOW TITLE
read i18n_main

# MENU ITEMS
read i18n_slideshow
read i18n_slideshow_tooltip
read i18n_options
read i18n_quit
read i18n_quit_tooltip
read i18n_file
read i18n_edit
read i18n_view
read i18n_help
read i18n_help_cli

# SUBJECT FRAME
read i18n_subject

# PLACEMENT FRAME
read i18n_placement
read i18n_live_preview
read i18n_live_preview_tooltip

# ACTION FRAME
read i18n_action
# buttons
read i18n_apply
read i18n_clear
read i18n_filer
read i18n_cancel
read i18n_undo
# tooltips
read i18n_apply_tooltip
read i18n_clear_tooltip
read i18n_edit_tooltip
read i18n_view_tooltip
read i18n_filer_tooltip
read i18n_undo_tooltip

# ABOUT WINDOW
read i18n_about_window
read i18n_about_text

# COMMAND-LINE HELP WINDOW
read i18n_help_cli_window

# PREFERENCES
read i18n_configuration_window
read i18n_conf_slideshow
read i18n_conf_slideshow_interval
read i18n_conf_slideshow_interval_tooltip
read i18n_conf_slideshow_shuffle
read i18n_conf_slideshow_shuffle_tooltip
read i18n_conf_slideshow_slide_dir
read i18n_conf_slideshow_slide_dir_tooltip
read i18n_conf_programs
read i18n_conf_shuffler
read i18n_conf_filemanager
read i18n_conf_img_editor
read i18n_conf_img_viewer
read i18n_conf_images
read i18n_conf_preferred_image_format
read i18n_conf_preferred_image_format_tooltip
read i18n_config_preferred_format_JPEG
read i18n_config_preferred_format_WEBP
read i18n_conf_subject_image_quality
read i18n_conf_wallpaper_image_quality
read i18n_conf_image_quality_tooltip
read i18n_conf_interface
read i18n_conf_colors_must_match
read i18n_conf_frame_rox
read i18n_conf_frame_internal
read i18n_conf_only_rox_can_change_setting
read i18n_conf_rox_how_change_bg_color
read i18n_conf_bg_color
read i18n_conf_show_exit_dialog
read i18n_save

# PROGRAM CHOOSER DIALOG
read i18n_program_chooser_window
read i18n_program_chooser_headers
read i18n_program_chooser_entry_hint

# STATUS BAR
read i18n_cached
read i18n_corrupt_file
read i18n_converted
read i18n_mimetype
read i18n_cur_wallpaper
read i18n_animated

# FILE INFO DIALOG
read i18n_file_info_window
read i18n_click_for_file_info
read i18n_exiftool_not_found
read i18n_preferred_image_format_fmt
read i18n_subject_and_wallpaper_quality_fmt
read i18n_bg_color_preference_fmt

# EXIT DIALOG
read i18n_dlg_exit_title
read i18n_dlg_exit_active_slideshow
read i18n_dlg_exit_active_slideshow_tooltip
read i18n_dlg_exit_show_exit_dialog
read i18n_dlg_exit_show_exit_dialog_tooltip
read i18n_dlg_exit_pixs_intro
read i18n_dlg_exit_wp
read i18n_dlg_exit_staged
read i18n_dlg_exit_initial
read i18n_dlg_exit_slide
read i18n_dlg_exit_export_to_chk
read i18n_dlg_exit_export_to_chk_tooltip
read i18n_dlg_exit_export_to_btn_tooltip
read i18n_another_slideshow_fmt

# MESSAGES
read i18n_restart_when_done
read i18n_invalid_option
read i18n_error_no_rox_fmt
read i18n_error_exclusive_lock
read i18n_error_breaking_lock
read i18n_error_invalid_config_fmt

# CLI SLIDESHOW
read i18n_cli_slideshow_running_fmt
read i18n_cli_slideshow_paused_fmt
read i18n_cli_slideshow_stopped_fmt
	} << EOF
$(gettext -es -- \
\
"Centre\n" \
"Tile\n" \
"Scale\n" \
"Fit\n" \
"Stretch\n" \
"Spread\n" \
"Display image as is, centred on the screen.\n" \
"Checkerboard effect for small images.\n" \
"Proportionally enlarge/reduce the image to fit its longer side.\n" \
"Proportionally enlarge/reduce the image to fit its shorter side.\n" \
"<b>Proportionally</b> enlarge/reduce the image to the smallest size that completely fills the screen.\n" \
"<b>Un-proportionally</b> enlarge/reduce the image to completely fill the screen. Images reshaped this way will look distorted if the image aspect ratio does not match the screen aspect ratio.\n" \
\
"Desktop Wallpaper\n" \
\
"Slideshow on/off\n" \
"Start/stop a slideshow. The <u>subject</u> determines the input source for the slideshow; <u>subject</u> = <b>folder</b> → the input source is the folder; <u>subject</u> = <b>file</b> → the input source is the file's folder.\n" \
"Edit preferences...\n" \
"Quit\n" \
"Quit this application without asking for confirmation.\n" \
"File\n" \
"Edit\n" \
"View\n" \
"Help\n" \
"Command line\n" \
\
"Subject\n" \
\
"Placement\n" \
"Preview\n" \
"<b>Preview</b> the <u>placement</u> of the selected <u>subject</u> image directly on your Desktop as you change the <u>subject</u>. You will need to click 'Apply' to make a change persist.\n" \
\
"Action\n" \
"Apply\n" \
"Clear\n" \
"Filer\n" \
"Cancel\n" \
"Undo\n" \
"Set the current <u>subject</u> image as your Desktop wallpaper.\n" \
"Purge cached previews. Images are cached for persistence, and are optimised for the current monitor. If you change your monitor or the background colour and images look odd try clicking the 'Clear' button then 'Apply' your wallpaper image again.\n" \
"Edit the current image <u>subject</u>.\n" \
"View the current image <u>subject</u>.\n" \
"Browse the current folder.\n" \
"Undo the last Desktop wallpaper change.\n" \
\
"About - Desktop Wallpaper\n" \
"Screen background image chooser and slideshow player.\r\rLicense: GNU General Public License.\r\rSee file LICENSE for copyright information.\n" \
\
"Command-line Help - Desktop Wallpaper\n" \
\
"Preferences - Desktop Wallpaper\n" \
"Slideshow\n" \
"Interval\n" \
"Period in seconds between two slides.\n" \
"Shuffle\n" \
"Shuffle the playlist before starting the slideshow.\n" \
"Slideshow:\n" \
"Default look-in directory - see Help > SLIDESHOW.\n" \
"Default programs\n" \
"Playlist shuffler\n" \
"File manager\n" \
"Image editor\n" \
"Image viewer\n" \
"Images\n" \
"Preferred image format\n" \
"This choice affects the time to generate subjects and wallpaper previews, disk usage, and export file format.\n" \
"JPEG files are universal.\n" \
"WEBP files are smaller and are generated faster.\n" \
"Subject image quality\n" \
"Wallpaper image quality\n" \
"Space-separated list of FILENAME_EXTENSION=INTEGER (0-100), e.g. <b>JPEG=75 WEBP=75</b>\n" \
"Interface\n" \
"For best results involving image transparency these two colours must match. Click the buttons to pick matching colours.\n" \
"ROX-Filer's background colour\n" \
"Subject's background colour\n" \
"Only ROX-Filer can change this setting.\n" \
"Open ROX, opposite-click an empty space, select Options → Pinboard → Appearance → Background...\n" \
"Background colour\n" \
"Show exit dialog\n" \
"Save\n" \
\
"Choose Program - Desktop Wallpaper\n" \
"Program | Command\n" \
"Enter a custom command or use the folder button to select a program.\n" \
\
"Cached\n" \
"Corrupt image or unsupported format feature:\n" \
"(converted)\n" \
"MIME-type:\n" \
"CURRENT WALLPAPER -\n" \
"animated\n" \
\
"File Info - Desktop Wallpaper\n" \
"Click for file info\n" \
"Suggested command \"exiftool\" is not installed.\n" \
"Preferred output image format: %s\n" \
"%s quality: %s%% (subject frame) and %s%% (screen wallpaper)\n" \
"Background color: %s\n" \
\
"Exit - Desktop Wallpaper\n" \
"Stop the current slideshow\n" \
"A slideshow is active. Check this box to stop the slideshow when this dialog will close.\n" \
"Show this exit dialog next time\n" \
"Check this box to skip this dialog in the future. You can enable it again in the Preferences dialog.\n" \
"Click an image below to <b>finalise</b> your choice and <b>close</b> this window:\n" \
"Last applied\n" \
"Unapplied preview\n" \
"Initial wallpaper\n" \
"Last slide\n" \
"Export current wallpaper image\n" \
"Export image to folder\n" \
"Click to select an export folder\n" \
"Another slideshow is active (%s). Stop it and start a new one?\n" \
\
"Restart Desktop Wallpaper when you are done.\n" \
"invalid option:\n" \
"User %s is not running ROX-Filer.\n" \
"Another Desktop Wallpaper dialog is running.\n" \
"Breaking lock.\n" \
"Configuration option '%s' = '%s' is invalid. Please edit your preferences.\n" \
\
"%d running (%d)\n" \
"%d paused (%d)\n" \
"%d stopped\n" \
)
EOF
}

## Create table
set -a; i18n_table; set +a

