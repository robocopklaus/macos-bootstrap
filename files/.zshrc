# ------------------------------
# Environment Setup
# ------------------------------

# Volta: JavaScript toolchains manager
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Homebrew environment setup
eval "$(/opt/homebrew/bin/brew shellenv)"

# Antidote: A plugin manager for Zsh
# Loads Antidote and its plugins
if command -v brew &> /dev/null; then
  # source antidote
  source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
  # initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
  antidote load
fi
