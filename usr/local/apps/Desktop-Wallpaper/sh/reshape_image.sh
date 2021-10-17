# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_reshape_image=$(($__loaded_reshape_image +1)) && echo >&2 "reshape_image.sh{$__loaded_reshape_image}"

# tsort func:get_screen_dims_and_aspect_ratio sh/reshape_image.sh
# tsort sh/reshape_image.sh var:RESHAPING_METHODS
# tsort sh/reshape_image.sh func:get_reshaping_output_formats

#######################################################################
#                               RESHAPE IMAGE                         #
#######################################################################
# recommended read https://en.wikipedia.org/wiki/Netpbm

get_reshaping_output_formats () { # $1-varname_image_formats
# Confident that the reshaping pipeline can output any of the following formats.
# These can be exposed to the user.

  local -n varname_image_formats="$1"
  # sorted alphabetically
  varname_image_formats="JPEG WEBP"
  # IMPORTANT            ^^^^ ^^^^
  # for each new FORMAT define __fallback_FORMAT_from_pnm in
  # image/image_reshape.sh
}

get_reshaped_image_new () { # $1-mode $2-gtkimg_in $3-varname_img_out $4-width $5-height $6-Z_encoding_sub $7-image_quality
# If mode $1 requires, reshape cached image $2.
# Return path of original $2 or reshaped $2 in variable $3.
# Return the empty string in $3 on error.
# This function provides its own implementations of all ROX reshaping styles,
# and more.  These implementations are slower but more accurate and of course
# extensible. With its own implementations AppRun does not depend on ROX-Filer
# except for impressing the Desktop in impress_backend_rox.sh.

  local mode="$1" gtkimg_in="$2" width="$4" height="$5" z_sub="$6" image_quality="$7" img_out origin
  local -n varname_img_out="$3"; varname_img_out=

  ((DEBUG)) && dprint_varname "$FUNCNAME:$LINENO" mode gtkimg_in >&2

  if [[ "$mode" =~ $RESHAPING_METHODS_RE ]]; then
    # Reshaped entirely by image pipeline
    # -----------------------------------
      get_cached_origin "$gtkimg_in" origin
      if get_cached_path_new "$origin" "$z_sub" "$mode" img_out; then # {N6}
        ((DEBUG)) && dprint_varname "$FUNCNAME:$LINENO" img_out >&2

        if [ ! -s "$img_out" ]; then
          mkdir -p "${img_out%/*}" &&
            reshape_image_with_method "${mode,,}" "$gtkimg_in" "$img_out" \
              "$width" "$height" "$image_quality" ||
            unset img_out
        fi
      fi
    # Reshaped by other means (currently none)
    # ---------------------------------------
  else
      img_out="$gtkimg_in"
  fi

  # reshape_image_with_method outputs an empty $img_out file on errors
  if [ -s "$img_out" ]; then
    varname_img_out="$img_out"
  else
    rm -f "$img_out"
  fi
}

#######################################################################
#                          RESHAPING METHODS                          #
#######################################################################
# Look at reshape_image_with_method to understand start_reshape_method_*

# Label "{ROX}" marks methods that also ROX-Filer has implemented.
# By the time set_rox_backdrop is called to set the backdrop, the candidate
# image must be rescaled in a way that Rox's own reshaping engine cannot
# destroy. This is accomplished by passing a ${SCREEN_WIDTH}x${SCREEN_HEIGHT}
# RGB image - alpha channel flattened.

# {ROX}
export RESHAPING_METHODS_RE='Centre'
start_reshape_method_centre () {
# This method centers the image as is in the box.
  call_image_func "$image_in" to_pnm "$image_in"
}

# {ROX}
RESHAPING_METHODS_RE+='|Scale'
start_reshape_method_scale() {
# This method proportionally scales the input image up/down to the largest size
# that fits its longer side completely in the box.
  local origin_width origin_height
  get_meta_image_dimensions "$image_in" origin_width origin_height ||
  # -----------------------------------------------------------------
    return 1
  # -----------------------------------------------------------------
  (($origin_width < $origin_height)) &&
    scale_image="-width $width" ||
    scale_image="-height $height"
  call_image_func "$image_in" to_pnm "$image_in" |
    command pamscale $filter $scale_image
}

# {ROX}
RESHAPING_METHODS_RE+='|Fit'
start_reshape_method_fit() {
# This method proportionally scales the input image up/down to the largest size
# that fits its shorter side completely in the box.
# Note: ROX-Filer's "Fit" style doesn't center the image. This does.
  local origin_width origin_height
  get_meta_image_dimensions "$image_in" origin_width origin_height ||
  # -----------------------------------------------------------------
    return 1
  # -----------------------------------------------------------------
  (($origin_width > $origin_height)) &&
    scale_image="-width $width" ||
    scale_image="-height $height"
  call_image_func "$image_in" to_pnm "$image_in" |
    command pamscale $filter $scale_image
}

# {ROX}
RESHAPING_METHODS_RE+='|Stretch'
start_reshape_method_stretch() {
# This method proportionally scales the input image up/down to the largest size
# that completely fills the box.
  call_image_func "$image_in" to_pnm "$image_in" |
    command pamscale $filter -width $width -height $height
}

RESHAPING_METHODS_RE+='|Spread'
start_reshape_method_spread () {
# This method proportionally scales the input image up/down to the smallest
# size that completely fills the box.
  call_image_func "$image_in" to_pnm "$image_in" |
    command pamscale $filter -xyfill $width $height
}

start_reshape_method_pixmap () {
# If the input image lies outside the box, this method proportionally scales
# the input image to the largest size that fits completely in the box.  If the
# input image lies inside the box it is left unchanged.
  local origin_width origin_height

  if get_meta_image_dimensions "$image_in" origin_width origin_height &&
    ((origin_width > width || origin_height > height))
  then
    call_image_func "$image_in" to_pnm "$image_in" |
      command pamscale $filter -xyfit $width $height
  else
    call_image_func "$image_in" to_pnm "$image_in"
  fi
}

# {ROX}
RESHAPING_METHODS_RE+='|Tile'
start_reshape_method_tile () {
# This method replicates the input image to fill the box.
  local stem="$RUNTIME_DIR/.$FUNCNAME.$$.$RANDOM"
  local __ nchannel
  trap "rm -f '$stem'.{ppm,pgm,meta}" RETURN

  call_image_func "$image_in" to_pnm "$image_in" |

    # extract + tile RGB channels to $stem.ppm
    tee >(pamchannel 0 1 2 | pnmtile $width $height > "$stem.ppm") |

    # if image has an alpha channel extract + tile it to $stem.ppm
    tee >(exec 2>/dev/null; pamchannel 3 |
        pnmtile $width $height > "$stem.pgm" || rm "$stem.pgm") > /dev/null

  [ -e "$stem.pgm" ] &&
    # stack tiled channels back together
    pamstack -quiet -tupletype="RGB_ALPHA" "$stem."{ppm,pgm} ||
    cat "$stem.ppm"
}

# ------------------------------------------------------------ #

reshape_image_with_method () { # $1-method $2-image_in $3-image_out $4-$width $5-$height $6-image_quality
# Scale an existing image $2 according to method $1 inside a ${4}x${5} viewport
# and set the result against a $BG_COLOR background.  Output to $3.

  local method="$1" image_in="$2" image_out="$3" width="$4" height="$5" image_quality="$6"
  local scale_image ret=0

  # Unsetting $filter makes pamscale(1) use "pixel-mixing".
  # Filter "hermite" is our default choice for increased quality.
  # pamscale filters include: point box triangle quadratic cubic catrom mitchell
  # gauss sinc bessel hanning hamming blackman kaiser normal hermite lanczos.
  local filter="$SCALE_FILTER"
  [ "$filter" = "pixel-mixing" ] && unset filter || filter="-filter=${filter:-hermite}"
  local underf underf_color bg_color="rgb:$BG_COLOR"

  ((DEBUG)) && dprint_varname "$FUNCNAME:$LINENO" method width height bg_color image_in >&2

  ## Create a solid color background file (underf or underf_color)
  # $underf and $underf_color are backgrounds for alpha transparent images.
  # They are created and cached here, and removed by on_signal.

  get_pbm_rect_new "$width" "$height" underf
  # performance: cache underf_color instead of recreating it each time
  if ((WALLPAPER_CACHE_LEVEL > 0)); then
    underf_color="${underf%.*}_${BG_COLOR//\/}.ppm"
    [ -s "$underf_color" ] || pgmtoppm "$bg_color" "$underf" > "$underf_color"
  fi

  ## Run reshaping pipeline

  # 1 convert input image to PAM with transparency
  # 2 scale PAM#1 up/down proportionally to fill the screen
  # 3 center align PAM#2 over a solid color background yielding PAM#3
  # 4 convert PAM#3 to a pixmap
  # 5 return the combined exit status of the pipelined processes

  if [ -n "$underf_color" ]; then
    start_reshape_method_$method | #1 #2
      command pamcomp -align center -valign middle - "$underf_color" | #3
      call_image_func "$image_in" from_pnm "-" "$image_quality" > "$image_out" #4

  else # same as above but #4 creates the color background file dynamically
    start_reshape_method_$method | #1 #2
      command pamcomp -align center -valign middle - <(command pgmtoppm "$bg_color" "$underf") | #3
      call_image_func "$image_in" from_pnm "-" "$image_quality" > "$image_out" #4
  fi

  ret=$(( ${PIPESTATUS[*]/#/+} )) #5

  return $ret
}

# ------------------------------------------------------------ #

get_pbm_rect_new () { # $1-width $2-height $3-varname_pbm_path
# Create and cache a ${1}x${2} white PBM image if it doesn't exist.
# Return the cached path in varname $3 or empty string on error.
# To compress $3: make_pgm_image W H | pnmtorle > out.rle
# To paint it a solid color: make_pgm_image W H |
#  pgmtoppm rgb:ff/00/00 [ | pnmtorle] > out.ppm[.rle]

  local -n varname_pbm_path="$3"; varname_pbm_path=
  local pbmf="$RUNTIME_DIR/.screen_bg_${1}x${2}.pbm"
  if [ -s "$pbmf" ]; then
    varname_pbm_path="$pbmf"
  elif pnmtile "$1" "$2" > "$pbmf" <<< "\
P1
24 8
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0"
  then varname_pbm_path="$pbmf"
  fi
}

# ------------------------------------------------------------ #

optimized_reshape_webp_with_method () { # $1-method $2-image_in $3-image_out $4-$width $5-$height $6-image_quality
# Scale an existing image $2 according to method $1 inside a ${4}x${5} viewport
# and set the result against a $BG_COLOR background.  Output to $3.
# ____
# Positional parameters consistent with reshape_image_with_method.
# Implemented for method $1==pixmap only to optimize for speed.
# This function is noticeably faster than `reshape_image_with_method "pixmap"`
# but it yields a different image wherein the subject is accurate but the input
# and output bounding boxes coincide and are <= ${4}x${5}.
# In contrast, `reshape_image_with_method` creates a ${4}x${5} image all the time.

  local method="$1" image_in="$2" image_out="$3" width="$4" height="$5" image_quality="$6"
  local scale_image ret=0
  local q="! $image_quality !"; q="${q#*WEBP=}"; q="${q%% *}"; case "$q" in *\!*) q=;; esac
  local bg_color="0x${BG_COLOR//\/}"
  local origin_width origin_height

  ## Set $scale_image in lieu of set_reshape_method_pixmap

  [ "pixmap" = "$method" ] &&
    get_meta_image_dimensions "$image_in" origin_width origin_height ||
    # -----------------------------------------------------------------
      return 1
    # -----------------------------------------------------------------
  if   (($origin_width >  $width && $origin_height <= $height)); then
    scale_image="-resize $width 0"
  elif (($origin_width <= $width && $origin_height >  $height)); then
    scale_image="-resize 0 $height"
  elif (($origin_width >  $width && $origin_height >  $height)); then
    (($origin_width < $origin_height)) &&
      scale_image="-resize $width 0" ||
      scale_image="-resize 0 $height"
  fi

  ((DEBUG)) && dprint_varname "$FUNCNAME:$LINENO" method width height bg_color image_in >&2

  ## Run reshaping pipeline

  # 1 convert input image to PAM with transparency
  # 2 scale PAM#1 down proportionally to fill the screen
  # 3 center align PAM#2 over a solid color background and
  # 4 convert to a pixmap
  # 5 return the combined exit status of the pipelined processes

  call_image_func "$image_in" to_pnm "$image_in" | #1
    cwebp -quiet ${q:+-q "$q"} -blend_alpha "$bg_color" \
    $scale_image -o "-" -- "-" > "$image_out" #2 #3 #4

  ret=$(( ${PIPESTATUS[*]/#/+} )) #5

  return $ret
}

# ------------------------------------------------------------ #

