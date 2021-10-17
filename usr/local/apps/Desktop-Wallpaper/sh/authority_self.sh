# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_authority_self=$(($__loaded_authority_self +1)) && echo >&2 "authority_self.sh{$__loaded_authority_self}"

# See starting comments in sh/authority_rox.sh

#######################################################################
#                             PERSISTENT                              #
#######################################################################

pull_apprun_wallpaper_state () { # $1-varname_mode $2-varname_img $3-varname_img_origin
# Read values from a persistent state file. Cf. get_apprun_wallpaper_state.

  local -n varname_mode="$1" varname_img="$2" varname_img_origin="$3"
  local mode img img_origin
  [ -s "$USRDIR/apprun_state" ] && source "$USRDIR/apprun_state"
  varname_mode="$bg_mode" varname_img="$bg_img" varname_img_origin="$bg_img_origin"
}

push_apprun_wallpaper_state () {
# Write volatile values to a persistent state file. Cf. set_apprun_wallpaper_state.
# Lifecycle: init apprun -> pull -> [gs]et (repeated) -> push -> exit

  local mode img img_origin
  get_apprun_wallpaper_state mode img img_origin
  printf "%s=%q\n" bg_mode "$mode" bg_img "$img" bg_img_origin "$img_origin" > "$USRDIR/apprun_state"
}

#######################################################################
#                               VOLATILE                              #
#######################################################################

get_apprun_wallpaper_state () { # $1-varname_mode $2-varname_img $3-varname_img_origin
# Pass "!" for any value you don't wish to get.
# Return: a triplet <reshape_mode, image_path, image_origin_path>, which is
# how AppRun's GUI's tracks the currently displayed wallpaper. This
# representation is accurate as long as the GUI is the sole actor changing the
# wallpaper. If instead additional actors, such as the slideshow or ROX-Filer
# and other programs, are all changing the wallpaper at the same time, AppRun's
# GUI's will lose track and the values returned will not reflect the displayed
# desktop wallpaper.

  local -n varname_mode varname_img varname_img_origin
  local -i err=0
  [ "$1" != "!" ] && varname_mode="$1" && varname_mode=
  [ "$2" != "!" ] && varname_img="$2" && varname_img=
  [ "$3" != "!" ] && varname_img_origin="$3" && varname_img_origin=

  if [ "$1" != "!" ] && [ -s "$RUNTIME_DIR/.bg_mode" ]; then
    read varname_mode < "$RUNTIME_DIR/.bg_mode" || err+=1
  fi
  if [ "$2" != "!" ] && [ -s "$RUNTIME_DIR/.bg_img" ]; then
    read varname_img < "$RUNTIME_DIR/.bg_img" || err+=2
  fi
  if [ "$3" != "!" ] && [ -s "$RUNTIME_DIR/.bg_img_origin" ]; then
    read varname_img_origin < "$RUNTIME_DIR/.bg_img_origin" || err+=4
  fi
  return $err
}

set_apprun_wallpaper_state () { # $1-bg_mode $2-bg_img $3-bg_img_origin
# Pass "!" for any value you don't wish to set.
# Spell mode value as British English infinitive verb for compatibility with
# 'rox --RPC'. Cf. sh/mode.sh
  local -i err=0
  if [ "$1" != "!" ]; then
    echo "$1" > "$RUNTIME_DIR/.bg_mode" || err+=1
  fi
  if [ "$2" != "!" ]; then
    echo "$2" > "$RUNTIME_DIR/.bg_img" || err+=2
  fi
  if [ "$3" != "!" ]; then
    echo "$3" > "$RUNTIME_DIR/.bg_img_origin" || err+=3
  fi
  return $err
}

clear_apprun_wallpaper_state () {
  rm -f "$RUNTIME_DIR/."{bg_mode,bg_img,bg_img_origin}
}

