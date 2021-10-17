# Convert plain text to pango markup

# see file ../LICENSE for license and version information

# Usage: $APPDIR/cli --help | awk -f help-text-to-pango-markup.awk

BEGIN {
	print "<span font=\"monospace\">"
}
{
	# convert sensitive characters to HTML entities
	gsub(/&/, "\x1");
	gsub(/</, "\\&lt;");
	gsub(/>/, "\\&gt;");
	gsub(/\x1/, "\\&amp;")

	print
}
END {
	print "</span>"
}
