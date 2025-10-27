# Initialize zinit plugin manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname $ZINIT_HOME)"

[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

source "${ZINIT_HOME}/zinit.zsh"

# Completions
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -a --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls -a --color $realpath'

zinit cdreplay -q

# sourcing mode for vi mode
ZVM_INIT_MODE=sourcing

# Plugins
zinit light Aloxaf/fzf-tab
zinit light fdellwing/zsh-bat
zinit light jeffreytse/zsh-vi-mode
zinit light jessarcher/zsh-artisan
zinit light z-shell/zsh-eza
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light mehalter/zsh-nvim-appname

# Oh My Zsh Plugins
zinit snippet OMZP::git
zinit snippet OMZP::ansible
zinit snippet OMZP::systemd
zinit snippet OMZP::firewalld
zinit snippet OMZP::ubuntu
zinit snippet OMZP::archlinux
zinit snippet OMZP::dnf
zinit snippet OMZP::sudo
zinit snippet OMZP::docker
zinit snippet OMZP::docker-compose
zinit snippet OMZP::ssh-agent

# ssh-agent settings
zstyle :omz:plugins:ssh-agent quiet yes
zstyle :omz:plugins:ssh-agent helper ksshaskpass
zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent identities id_ed25519

# find ~/.ssh -name 'id_*' ! -name '*.pub' -exec ssh-add -q {} \; >/dev/null

# WordChars for more granular delete with control w
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Keybings
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

bindkey '^y' autosuggest-accept
bindkey '^ ' autosuggest-execute
bindkey '^b' autosuggest-clear

bindkey '^H' backward-kill-word
bindkey '^[[3;5~' kill-word

bindkey '^[t' sesh-sessions

# Sesh on alt-t
function sesh-sessions() {
  {
    sesh connect $(
      sesh list | fzf \
        --reverse --no-sort --border-label ' sesh ' --prompt '⚡  ' \
        --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
        --bind 'tab:down,btab:up' \
        --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
        --bind 'ctrl-t:change-prompt(  )+reload(sesh list -t)' \
        --bind 'ctrl-g:change-prompt(󱦞 )+reload(sesh list -c)' \
        --bind 'ctrl-x:change-prompt(  )+reload(sesh list -z)' \
        --bind 'ctrl-f:change-prompt(󰍉  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
        --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(  )+reload(sesh list)'
    )
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '\et' sesh-sessions
bindkey -M vicmd '\et' sesh-sessions
bindkey -M viins '\et' sesh-sessions

# History
HISTSIZE=5000
HISTFILE="$HOME/.zsh_history"
SAVEHIST="$HISTSIZE"
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Zshell options
setopt no_beep
setopt auto_cd

# Aliases
alias gs="git status"
alias gpl="git pull"
alias gpoat="git push origin --all && git push origin --tags"
alias lg="lazygit"
alias fm="yazi"
alias tsu="sudo tailscale up --accept-routes --ssh --operator=$USER"
alias tsd="sudo tailscale down"
alias lap="eza -alh | bat -l fs"
alias cl="clear"
alias v="nvim"
alias n="nvim"
alias vim="nvim"
alias t=sesh-sessions
alias -- -='cd -'
alias ...='cd ../..'
alias ....='cd ../../..'
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'

# Global Aliases
alias -g ...='../..'
alias -g ....='../../..'

s () {
  local server
  server=$(grep -E '^Host ' ~/.ssh/config | awk '{print $2}' | fzf)
  if [[ -n $server ]]; then
    kitten ssh $server
  fi
}

# Functions
function mkcd takedir() {
  mkdir -p $@ && cd ${@:$#}
}

function takeurl() {
  local data thedir
  data="$(mktemp)"
  curl -L "$1" > "$data"
  tar xf "$data"
  thedir="$(tar tf "$data" | head -n 1)"
  rm "$data"
  cd "$thedir"
}

function takegit() {
  git clone "$1"
  cd "$(basename ${1%%.git})"
}

function take() {
  if [[ $1 =~ ^(https?|ftp).*\.(tar\.(gz|bz2|xz)|tgz)$ ]]; then
    takeurl "$1"
  elif [[ $1 =~ ^([A-Za-z0-9]\+@|https?|git|ssh|ftps?|rsync).*\.git/?$ ]]; then
    takegit "$1"
  else
    takedir "$@"
  fi
}

# Source fast-syntax-highlighting theme
if [[ -z $(fast-theme -s | grep $COLOR_SCHEME) ]]; then
    fast-theme XDG:$COLOR_SCHEME > /dev/null
fi

# Create bat cache if missing
if [[ ! -d "$HOME/.cache/bat" ]]; then
    bat cache --build >/dev/null
fi

# FZF
eval "$(fzf --zsh)"

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# Direnv
if [[ $(command -v direnv) ]]; then
    export DIRENV_LOG_FORMAT=''
    eval "$(direnv hook zsh)"
fi

# Starship
if [[ ! $(command -v starship) ]]; then
    curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin
fi

eval "$(starship init zsh)"


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Set Kitty Window Title
DISABLE_AUTO_TITLE="true"
function stitle() {
  echo -en "\e]2;$@\a"
}
# Example to set title to current working directory:
precmd_functions+=(update_kitty_title)
function update_kitty_title() {
  stitle $(basename $(pwd))
}

if [[ -d "$HOME/.config/herd-lite/bin/" ]]; then
  export PATH="$HOME/.config/herd-lite/bin:$PATH"
  export PHP_INI_SCAN_DIR="$HOME/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
fi
