# This BASH shell file is sourced not run
((DEBUG)) && export __loaded_stack=$(($__loaded_stack +1)) && echo >&2 "stack.sh{$__loaded_stack}"

#######################################################################
#                          FILE-BASED STACK                           #
#######################################################################

stack_clear () { # $1-stack_name
  ((DEBUG>1)) && dprint "$FUNCNAME" "($1)" >&2
  : > "$RUNTIME_DIR/.$1"
}

stack_push () { # $1-stack_name $2-item ; EOF is TOS
  ((DEBUG>1)) && dprint "$FUNCNAME" "($1)" "($2)" >&2
  echo "$2" >> "$RUNTIME_DIR/.$1"
}

stack_pop () { # $1-stack_name $2-varname_last_popped [$3-N]
# Pass "!" for $2 if you don't wish to get its value.
# pop at most N items (default 1 == TOS) then return the last popped item
# error exit status if fewer than N items were popped
  local name="$1"
  [ "$2" != "!" ] && local -n varname_last_popped="$2"
  local -i n="${3:-1}" max err
  local -a a

  mapfile -t a < "$RUNTIME_DIR/.$name"; err=$?
  max=$((${#a[*]} - n))
  for (( i = 0; i < max; i++ )); do
    printf "%s\n" "${a[i]}"
    err+=$?
  done > "$RUNTIME_DIR/.$name"
  if [ "$2" != "!" ]; then
    if ((max >= 0)); then
      varname_last_popped="${a[max]}"
    elif ((${#a[*]})); then
      varname_last_popped="${a[${#a[*]} - 1]}"
    fi
  fi
  ! ((err || max < 0))
}

stack_tos () { # $1-stack_name $2-varname_tos
# error exit status if stack is empty
  local name="$1"
  local -n varname_tos="$2"
  local -a a
  mapfile -t a < "$RUNTIME_DIR/.$name" &&
    ((${#a[@]})) && varname_tos="${a[-1]}"
}

# not used
stack_pop_posix () { # $1-stack_name [$2-N]
# pop at most N items (default 1 == TOS) then output the last popped item
# return error if fewer than N items were popped
  local name="$1" n="${2:-1}"
  awk '{ R[NR] = $0 }
  END {
    printf "" > FILENAME
    err = (NR < '$n')
    if (!err) {
      for (i = 1; i <= NR - '$n'; i++)
        print R[i] > FILENAME
    }
    last = (err ? 1 : (NR - '$n' + 1))
    print R[last]
    exit (err)
  }' "$RUNTIME_DIR/.$name"
}

