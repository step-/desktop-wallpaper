# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_image_stderr=$(($__loaded_image_stderr +1)) && echo >&2 "image_stderr.sh{$__loaded_image_stderr}"

#######################################################################
#                STDERR FILTER FOR IMAGE PIPELINE                     #
#######################################################################

# This file implements a simple coprocess that filters its input on FIFO
# $RUNTIME_DIR/stderr discarding lines that match known harmless errors messages.
# Function image.sh:call_image_func redirects its stderr to the FIFO to discard
# error messages such as "fwrite() failed to write an image row to the file.
# errno=32 (Broken pipe)" ouput by image_meta.sh:extract_image_meta. This known
# error message is harmless and can be ignored because the awk process in
# extract_image_meta exits early on purpose, thus cutting off stdout for the
# upstream pipe process, which complains about the broken pipe.  Many netpbm
# commands output similar error messages, which the filter coprocess will
# discard.

# AppRun should take care of calling {start,stop}_stderr_filter_coprocess.
# If the coprocess isn't running when call_image_func is called, error output,
# if any, is appended to the regular file "$RUNTIME_DIR/stderr".

start_stderr_filter_coprocess () {
	stop_stderr_filter_coprocess
	if rm -f "$RUNTIME_DIR/stderr" && mkfifo -m 0600 "$RUNTIME_DIR/stderr"; then
	coproc {
		exec 3<> "$RUNTIME_DIR/stderr"
		>&2 <&3 awk -f <(echo '
		# DEBUG: uncomment next line to print all errors
		# { print }
		# error filter: exclude matching errors
		/errno=32|Short write of/ { next }
		# print non-matching errors
		{ printf "\033[31m%s\033[0m\n", $0 } # ANSI red
		{ fflush() } ') &
		echo $! > "$RUNTIME_DIR/stderr.pid"
		exec 2>&-
		wait $!
		}
	fi
}

stop_stderr_filter_coprocess () {
	local pid
	if [ -s "$RUNTIME_DIR/stderr.pid" ] && read pid < "$RUNTIME_DIR/stderr.pid" && kill -0 $pid 2>/dev/null; then
		kill $pid 2> /dev/null
		wait $pid 2> /dev/null
	fi
	rm -f "$RUNTIME_DIR/stderr"{,.pid}
}
