if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set PATH to use asdf
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
path=("$ASDF_DATA_DIR/bin" $path)


# Load Mikroways personalizations
[[ -f ~/.zshrc.mikroways ]] && source ~/.zshrc.mikroways

# Ensure tmux accepts UTF8
alias tmux="tmux -u"

# SSH alias with s
alias s=ssh

# Use vim-gtk3 as EDITOR
export EDITOR=vim

# Ctrl+U works like bash
bindkey "^u" backward-kill-line

# Alias for common extensions
alias -s {yaml,yml,json,md}=$EDITOR

# Fix GPG AGENT
export GPG_TTY=$TTY

source ~/.antigen.zsh/antigen.zsh

antigen use ohmyzsh/ohmyzsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
plugins=(aliases git git-extras pip command-not-found)

antigen bundle zsh-users/zsh-syntax-highlighting

antigen theme romkatv/powerlevel10k

# Mikroways bundles
[[ -f ~/.zshrc.mikroways.antigen.bundles ]] && \
  source ~/.zshrc.mikroways.antigen.bundles

# User bundles
[[ -f ~/.zshrc.user.antigen.bundles ]] && \
  source ~/.zshrc.user.antigen.bundles

# Tell Antigen that you're done.
antigen apply

# Do not share history between sessions
unsetopt share_history

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Fuzzy find
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Load custom autocomplete
fpath=($HOME/.zsh/completion $fpath)



[[ -f ~/.zshrc.mikroways.updates ]] && source ~/.zshrc.mikroways.updates

# Load Other User personalizations
[ -f ~/.zshrc.user ] && source ~/.zshrc.user
