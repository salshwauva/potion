# Potion shell integration shim. See .zshenv for the ZDOTDIR handling rationale.

POTION_SHIM_DIR=$ZDOTDIR
ZDOTDIR=${POTION_USER_ZDOTDIR:-$HOME}
[[ -f $ZDOTDIR/.zshrc ]] && source $ZDOTDIR/.zshrc
POTION_USER_ZDOTDIR=$ZDOTDIR
ZDOTDIR=$POTION_SHIM_DIR

# Load command tracking after the user's interactive configuration so the hooks
# and prompt marker are applied last, then hand ZDOTDIR back for the session.
[[ -f $POTION_SHIM_DIR/potion-integration.zsh ]] && source $POTION_SHIM_DIR/potion-integration.zsh
ZDOTDIR=$POTION_USER_ZDOTDIR
