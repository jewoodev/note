eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="$HOME/.local/bin:$PATH"

export SDKMAN_DIR="$HOME/.sdkman"
if (( ! $+functions[sdk] )) && [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
