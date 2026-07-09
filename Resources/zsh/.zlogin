# Potion shell integration shim. See .zshenv for the ZDOTDIR handling rationale.
# By the time login shells reach this point ZDOTDIR has usually been handed back
# to the user, so their own .zlogin loads directly. This file remains for the
# case where the shim is still active.

POTION_SHIM_DIR=$ZDOTDIR
ZDOTDIR=${POTION_USER_ZDOTDIR:-$HOME}
[[ -f $ZDOTDIR/.zlogin ]] && source $ZDOTDIR/.zlogin
POTION_USER_ZDOTDIR=$ZDOTDIR
ZDOTDIR=$POTION_SHIM_DIR
