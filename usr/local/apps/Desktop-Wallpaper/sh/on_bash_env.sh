# This BASH shell file is sourced not run

# This file is appended at the end of file $BASH_ENV when $DEBUG is non-zero,
# therefore it runs immediately before gtkdialog actions and conditions that
# start with "bash -c" ($BASH_EXECUTION_STRING), and immediately before a
# script run by AppRun or one of its subscripts runs.

### Show $BASH_ENV execution command or script command line
echo -n "__${BASH_ENV##*/} ${BASH_EXECUTION_STRING:-$(dprint${DEBUG_WITH_BASENAME}_args $$)}" >&2

case "$BASH_EXECUTION_STRING" in
	"swap_pixmap"* | "status_bar_msg"* )
		echo -n " FILE_CURSOR($FILE_CURSOR)" >&2
		;;
	*'$LIVE'*)
		echo -n " LIVE($LIVE)" >&2
		;;
esac

# EOL
echo >&2

# more stuff here
