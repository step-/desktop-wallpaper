# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_state=$(($__loaded_state +1)) && echo >&2 "state.sh{$__loaded_state}"

#######################################################################
#                    ENCAPSULATE STATE FILES                          #
#######################################################################

# tsort sh/stack.sh sh/state.sh

# ------------------------------------------------------------ #
# file '.staged_change'
# '.staged_change' denotes a staged change that can revert on exit.
# AppRun GUI stages change when the Preview mode is active, and
# commits '.staged_change' when the user clicks 'Apply' to persist
# the displayed wallpaper change.

stage_change () { # $1_mode $2_img $3-img_origin
  printf "%s\n" "${1:-error_in_$FUNCNAME}${2:+ }$2" "$3" > "$RUNTIME_DIR/.staged_change"
}

commit_change () {
  printf "%s\n" "${1:-error_in_$FUNCNAME}${2:+ }$2" "$3" > "$RUNTIME_DIR/.last_commit"
  rm -f "$RUNTIME_DIR/.staged_change"
}

is_change_staged () {
  [ -s "$RUNTIME_DIR/.staged_change" ] # -s !
}

get_staged_change () { # $1-varname_mode $2-varname_img $3_varname_img_origin
  local -n varname_mode="$1" varname_img="$2" varname_img_origin="$3"
  varname_mode= varname_img= varname_img_origin=
  is_change_staged &&
    { read varname_mode varname_img; read varname_img_origin; } < "$RUNTIME_DIR/.staged_change"
}

get_last_commit () { # $1-varname_mode $2-varname_img $3_varname_img_origin
  local -n varname_mode="$1" varname_img="$2" varname_img_origin="$3"
  varname_mode= varname_img= varname_img_origin=
  [ -s "$RUNTIME_DIR/.last_commit" ] &&
    { read varname_mode varname_img; read varname_img_origin; } < "$RUNTIME_DIR/.last_commit"
}

# ------------------------------------------------------------ #
# file '.restore_point'
# '.restore_point' is used to back-fill the undo stack,
# and as a restore point by on_signal EXIT.

set_restore_point () { # $1-bg_mode [$2-bg_img]
  stack_push restore_point "${1:-error_in_$FUNCNAME}${2:+ }$2"
}

get_restore_point () { # $1-varname_bg_mode $2-varname_bg_img $3-varname_bg_img_origin
  local -n varname_bg_mode="$1" varname_bg_img="$2" varname_bg_img_origin="$3"
  local point
  stack_tos restore_point point
  varname_bg_mode="${point%% *}"
  varname_bg_img="${point#$varname_bg_mode}"
  varname_bg_img="${varname_bg_img# }"
  get_cached_origin "$varname_bg_img" varname_bg_img_origin
}

unset_restore_point () {
  stack_pop restore_point "!"
}

# ------------------------------------------------------------ #
# file '.last_slide'
# impress_wallpaper saves into '.slideshow_state' the wallpaper impressed by a
# slideshow.

set_slideshow_state () { # $1-mode $2-img $3-img_origin $4-playlist_index
  printf "%s\n" "$1 $2" "$3" "$4" > "$RUNTIME_DIR/.slideshow_state"
}

get_slideshow_state () { # $1-varname_mode $2-varname_img $3-varname_img_origin $4-varname_playlist_index
  local -n varname_mode="$1" varname_img="$2" varname_img_origin="$3" playlist_index="$4"
  varname_mode= varname_img= varname_img_origin= playlist_index=

  if [ -s "$RUNTIME_DIR/.slideshow_state" ]; then
    { read varname_mode varname_img
      read varname_img_origin
      read varname_playlist_index
    } < "$RUNTIME_DIR/.slideshow_state"
  fi
}

reset_slideshow_state () {
  rm -f "$RUNTIME_DIR/.slideshow_state"
}
