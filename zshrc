if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/bin:$HOME/.mikroways/bin:$PATH"

# Use vim-gtk3 as EDITOR
export EDITOR=vim.gtk3

# Ctrl+U works like bash
bindkey "^u" backward-kill-line

# Enable rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
type rbenv > /dev/null && eval "$(rbenv init -)"

# Enable goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
type goenv > /dev/null && eval "$(goenv init -)"
type goenv > /dev/null && export PATH="$GOROOT/bin:$PATH:$GOPATH/bin"

# Enable nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Enable krew
KREW_ROOT=$HOME/.krew
[ -d $KREW_ROOT/bin ] && export PATH="$KREW_ROOT/bin:$PATH"

# Enable mw vpn connect
export MW_VPN_ROOT="$HOME/.mikroways/tools/mw-vpn"
[ -x $MW_VPN_ROOT/bin/mw-vpn ] && export PATH="$MW_VPN_ROOT/bin:$PATH" && \
  fpath=($MW_VPN_ROOT/shell-completion/zsh $fpath)

# Enable mw sshconfig sync
export MW_SSHCONFIG_SYNC_ROOT="$HOME/.mikroways/tools/mw-sshconfig-sync"
[ -x $MW_SSHCONFIG_SYNC_ROOT/bin/mw-sshconfig-sync ] && export PATH="$MW_SSHCONFIG_SYNC_ROOT/bin:$PATH"

# Enable mw gitlab clone
export MW_GITLAB_CLONE="$HOME/.mikroways/tools/mw-gitlab-clone"
[ -x $MW_GITLAB_CLONE/mw-gitlab-clone ] && export PATH="$MW_GITLAB_CLONE:$PATH"

source ~/.antigen.zsh/antigen.zsh

antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle ansible
antigen bundle aws
antigen bundle bundler
antigen bundle common-alias
antigen bundle direnv
antigen bundle docker
antigen bundle docker-compose
antigen bundle git
antigen bundle git-extras
antigen bundle pip
antigen bundle command-not-found
antigen bundle kubectl
antigen bundle johanhaleby/kubetail

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme.
antigen theme romkatv/powerlevel10k

# Tell Antigen that you're done.
antigen apply


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fpath=($fpath ~/.zsh/completion)
autoload -U +X compinit && compinit
complete -C '~/bin/aws_completer' aws

mkdir -p ~/.zsh/completion
for app in kubectl helm velero podman; do
  type $app > /dev/null && \
    [ ! -f ~/.zsh/completion/_$app ] && \
    $app completion zsh > ~/.zsh/completion/_$app
done

# Ensure tmux accepts UTF8
alias tmux="tmux -u"

# SSH alias with s
alias s=ssh

# Alias for common extensions

alias -s {yaml,yml,json,js,rb,py,md}=$EDITOR

# Make zsh Ctrl+U works like in bash
bindkey \^U backward-kill-line

# Fix GPG AGENT 
export GPG_TTY=$TTY

unsetopt share_history


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
