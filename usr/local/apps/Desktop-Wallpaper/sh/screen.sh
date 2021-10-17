# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_screen=$(($__loaded_screen +1)) && echo >&2 "screen.sh{$__loaded_screen}"

#######################################################################
#                     ASSORTED SCREEN FUNCTIONS                       #
#######################################################################

# tsort sh/screen.sh func:get_screen_dims_and_aspect_ratio

get_screen_dims_and_aspect_ratio () { # $1-varname_width $2-varname_height $3-varname_aspectratio
# Return screen width, height and aspect ratio (percentage in "%03d" printf format)
	local -n varname_width="$1" varname_height="$2" varname_aspectratio="$3"
	local w h ar __

	# cache for performance - AppRun removes .screen_dims on exit
	if [ -s "$RUNTIME_DIR/.screen_dims" ]; then
		read w h ar < "$RUNTIME_DIR/.screen_dims"
	else
		IFS=' x+' read __ w h __ < <(xwininfo -root | grep -F -- '-geometry')
		printf -v ar "%03d" $(( w * 100 / h ))
		echo "$w $h $ar" > "$RUNTIME_DIR/.screen_dims"
	fi
	varname_width="$w" varname_height="$h" varname_aspectratio="$ar"
}

