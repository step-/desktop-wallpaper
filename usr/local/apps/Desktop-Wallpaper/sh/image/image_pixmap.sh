# This POSIX shell file is sourced not run
[ ${DEBUG:-0} -gt 0 ] && export __loaded_image_pixmap=$(($__loaded_image_pixmap +1)) && echo >&2 "image_pixmap.sh{$__loaded_image_pixmap}"

#######################################################################
#            CONVERT ORIGIN IMAGE FOR THE PIXMAP WIDGET               #
#######################################################################

# TL;DR: EXT_to_pixmap () $1 => $2 (GtkImage pixmap)

# EXT_to_pixmap functions for get_pixmap_new and get_wpimage_new _must_
# convert an input origin $1 to a new image file $2, whose format the GtkImage
# toolkit can display natively{N2} while preserving $1's image transparency.
# ____
# {N2}: natively by means of an installed GDK pixbufloaderEXT.so library
# Be wary that some pixbuf loaders may not preserve transparency or err on
# specific image properties, e.g. WEBP animation. Always test these cases.

# Implementation options:
# EXT_to_pixmap can be implemented as one of the following options:
# 1. a symlink,    e.g. EXT_to_pixmap () { ln -s "$1" "$2"; }
# 2. a conversion, e.g. EXT_to_pixmap () { EXT_to_png "$1" "$2"; }
# Option 1 is recommended when it meets all requirements. Note that option 1
# will not scale down $1.

# After returning from EXT_to_pixmap, the contents of file $2, or of $2's
# target file, will be further processed; file $2 - not its target if $2 is a
# symbolic link file - will be overwritten.

# Function names must start with the file name extension of the input type.
# The same input type can be represented by multiple extension, e.g. JPG/JPEG.
# Define a function for each supported extension.

# Example of option 1:
#     png_to_pixmap () { ln -s -- "$1" "$2"; }
# Example of option 2:
#     jpg_to_pixmap () { jpegtopnm -- "$1";  }

# ------------------------------------------------------------ #

# no transparency: JPEG
# transparent => transparent: BMP, PNG, GIF, TIFF
# animated => still: GIF
__fallback_to_pixmap () { ln -sf -- "$1" "$2"; }

