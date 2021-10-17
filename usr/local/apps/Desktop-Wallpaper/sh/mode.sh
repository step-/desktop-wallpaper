# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_mode=$(($__loaded_mode +1)) && echo >&2 "mode.sh{$__loaded_mode}"

#######################################################################
#                ASSORTED FUNCTIONS FOR APPRUN'S MODE                 #
#######################################################################

# "Mode", a.k.a. "Placement" in the English language file (i18n_table.sh),
# refers to the image reshaping method that is used to place an input image in
# a specific position at a specific size on the screen.

# Note {N3} - What's the deal with mode "Spread?"
# Rox implements a non-proportional reshaping method named "Stretch _style_".
# AppRun implements that as "Stretch _mode_" and also a proportional method
# named "Spread" _mode_"; Cf.get_reshaped_image_new.  The source code uses
# "mode" to refer to AppRun's definition, and "style" for Rox's.

# The mapping "Rox:style <=> AppRun:mode" isn't one-to-one: both modes
# "Stretch" and "Spread" map on ROX's style "Stretch".
#                    ╭─▶ Spread mode (reshape_image_with_method "spread")
#    Stretch style ──+
#                    ╰─▶ Stretch mode (reshape_image_with_method "stretch")
# Therefore, in going mode => style to impress the Desktop with a wallpaper
# using the ROX impression backend, Cf. impress.sh, we need to pass "Stretch" to
# the ROX backend, and call apprun_mode_to_rox_style in impress_wallpaper
# to map mode => style per the diagram above.

# Similarly, when we read Rox's $PINBOARD_FILE and find <style>Stretch</style>
# we must be careful to map the style back to the correct mode. This is
# accomplished by rox_style_to_apprun_mode {N4}.

apprun_mode_to_rox_style () { # $1-mode $2-varname_style
# "apprun:mode -> "rox:style" mapping
	local mode="$1"
	local -n varname_style="$2"
	[ "$mode" = "Spread" ] && varname_style="Stretch" || varname_style="$mode"
}

rox_style_to_apprun_mode () {
# {N4} this function is just a placeholder for this comment:
# get_rox_backdrop implements the "rox:style -> apprun:mode" mapping.
	return 1
}

get_canonical_mode () { # $1-mode $2-varname_mode
# Convert $1 to UK-spelling infinitive verb as required by "rox --RPC"
	local mode="$1"
	local -n varname_mode="$2"
	case $MODE in
		Scale*            ) MODE=Scale ;;
		Fit*              ) MODE=Fit ;;
		Stretch*          ) MODE=Stretch ;;
		Spread*           ) MODE=Spread ;; # See {N3}
		Tile*             ) MODE=Tile ;;
		Center*|Centre*|* ) MODE=Centre ;; # sensible catchall
	esac
}

# tsort sh/i18n_table.sh sh/mode.sh
get_localized_mode_label () { # $1-mode $2-varname_locmode $3-varname_loclabel
# Return localized mode and label for English mode "$1"
	local mode="$1"
	local -n varname_locmode="$2" varname_loclabel="$3"
	case "$mode" in
		Stretch*          ) varname_locmode="$i18n_stretch" varname_loclabel="$i18n_stretch_tooltip" ;;
		Spread*           ) varname_locmode="$i18n_spread"  varname_loclabel="$i18n_spread_tooltip" ;;
		Tile*             ) varname_locmode="$i18n_tile"    varname_loclabel="$i18n_tile_tooltip" ;;
		Scale*            ) varname_locmode="$i18n_scale"   varname_loclabel="$i18n_scale_tooltip" ;;
		Fit*              ) varname_locmode="$i18n_fit"     varname_loclabel="$i18n_fit_tooltip" ;;
		# '*' Most sensible catchall -- but it shouldn't happen
		Centre*|Center*|* ) varname_locmode="$i18n_centre"  varname_loclabel="$i18n_centre_tooltip" ;;
	esac
}
