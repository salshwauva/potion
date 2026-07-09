# Potion shell integration shim. See .zshenv for the ZDOTDIR handling rationale.

POTION_SHIM_DIR=$ZDOTDIR
ZDOTDIR=${POTION_USER_ZDOTDIR:-$HOME}
[[ -f $ZDOTDIR/.zprofile ]] && source $ZDOTDIR/.zprofile
POTION_USER_ZDOTDIR=$ZDOTDIR
ZDOTDIR=$POTION_SHIM_DIR
