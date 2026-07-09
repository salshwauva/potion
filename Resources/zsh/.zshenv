# Potion shell integration shim.
#
# ZDOTDIR points here so the shim files load. Each file temporarily restores the
# user's own ZDOTDIR, sources their matching startup file, captures any change
# they made to ZDOTDIR, then points ZDOTDIR back at this shim so the remaining
# files still run. The user's configuration is never edited on disk.

POTION_SHIM_DIR=$ZDOTDIR
ZDOTDIR=${POTION_USER_ZDOTDIR:-$HOME}
[[ -f $ZDOTDIR/.zshenv ]] && source $ZDOTDIR/.zshenv
POTION_USER_ZDOTDIR=$ZDOTDIR
ZDOTDIR=$POTION_SHIM_DIR
