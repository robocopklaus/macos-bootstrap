# ------------------------------
# Environment Setup
# ------------------------------

# Volta: JavaScript toolchains manager
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"

# Homebrew environment setup
eval "$(/opt/homebrew/bin/brew shellenv)"

# Oh My Posh: A prompt engine for any shell
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.omp.json)"

# Antidote: A plugin manager for Zsh
# Loads Antidote and its plugins
if command -v brew &> /dev/null; then
  # source antidote
  source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
  # initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
  antidote load
fi
