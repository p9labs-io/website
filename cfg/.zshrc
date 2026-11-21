# HOW TO SWITCH YOUR DEFAULT SHELL TO ZSH:
# 1. Install zsh & optional plugins (if not already installed):
#    - Debian/Ubuntu: sudo apt update && sudo apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting
#    - macOS (Brew):  brew install zsh zsh-autosuggestions zsh-syntax-highlighting
#
# 2. Verify zsh is listed in /etc/shells:
#    command -v zsh | sudo tee -a /etc/shells
#
# 3. Change the default login shell for your current user:
#    chsh -s "$(command -v zsh)"
#
# 4. Log out and log back in (or start a new SSH session) to apply.
# ==============================================================================

# Exit immediately if the shell is non-interactive
[[ -o interactive ]] || return

# ------------------------------------------------------------------------------
# 1. Environment & Exports
# ------------------------------------------------------------------------------
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export EDITOR="vim"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R -F -X"

# Ensure local user binaries take precedence
typeset -U path PATH
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    /opt/homebrew/bin
    /usr/local/bin
    $path
)
export PATH

# ------------------------------------------------------------------------------
# 2. History Configuration
# ------------------------------------------------------------------------------
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY          # Record timestamp and duration of each command
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS          # Do not record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found
setopt HIST_IGNORE_SPACE         # Do not record an entry starting with a space
setopt HIST_SAVE_NO_DUPS         # Do not write duplicate entries in the history file
setopt SHARE_HISTORY             # Share history across all concurrent sessions

# ------------------------------------------------------------------------------
# 3. Shell Options & Navigation
# ------------------------------------------------------------------------------
setopt AUTO_CD                   # Type directory name to cd into it
setopt AUTO_PUSHD                # Make cd push the old directory onto the directory stack
setopt PUSHD_IGNORE_DUPS         # Do not push multiple copies of the same directory
setopt INTERACTIVE_COMMENTS      # Allow comments (#) in interactive shells
setopt NO_BEEP                   # Disable terminal bell

# ------------------------------------------------------------------------------
# 4. Completion System (Native Zsh)
# ------------------------------------------------------------------------------
autoload -Uz compinit
# Regenerate compdump only once a day for fast shell startup
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

zstyle ':completion:*' menu select                                 # Interactive arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'          # Case-insensitive matching
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"            # Colored completion lists
zstyle ':completion:*' rehash true                                 # Auto-find new executables in $PATH
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZDOTDIR:-$HOME}/.zsh_cache"

# ------------------------------------------------------------------------------
# 5. Keybindings (Emacs mode + Prefix History Search)
# ------------------------------------------------------------------------------
bindkey -e

# Search history using current input prefix with Up/Down arrows
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search     # Up arrow
bindkey '^[[B' down-line-or-beginning-search   # Down arrow
bindkey '^[OA' up-line-or-beginning-search     # Up arrow (application mode)
bindkey '^[OB' down-line-or-beginning-search   # Down arrow (application mode)

# Fix Home, End, Delete, and Ctrl+Left/Right navigation across terminals
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ------------------------------------------------------------------------------
# 6. Prompt with Native Git Integration (vcs_info)
# ------------------------------------------------------------------------------
autoload -Uz vcs_info
setopt PROMPT_SUBST

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b%u%c)%f'
zstyle ':vcs_info:git:*' actionformats ' %F{red}(%b|%a)%f'

precmd() {
    vcs_info
}

# Highlight root prompt in red, standard user in green
if [[ $EUID -eq 0 ]]; then
    PROMPT='%F{red}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_} %F{red}#%f '
else
    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_} %F{cyan}$%f '
fi

# ------------------------------------------------------------------------------
# 7. Aliases & Utility Functions
# ------------------------------------------------------------------------------
# Cross-platform ls colors (GNU Linux vs BSD/macOS)
if ls --color=auto / >/dev/null 2>&1; then
    alias ls='ls --color=auto'
else
    alias ls='ls -G'
fi

alias ll='ls -lahF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Safety & convenience
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ports='ss -tulanp'
alias reload='exec zsh'

# Quick directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Extract any archive cleanly
extract() {
    if [[ ! -f "$1" ]]; then
        echo "Error: '$1' is not a valid file." >&2
        return 1
    fi
    case "$1" in
        *.tar.bz2) tar xjf "$1"     ;;
        *.tar.gz)  tar xzf "$1"     ;;
        *.tar.xz)  tar xJf "$1"     ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.bz2)     bunzip2 "$1"     ;;
        *.rar)     unrar x "$1"     ;;
        *.gz)      gunzip "$1"      ;;
        *.tar)     tar xf "$1"      ;;
        *.tbz2)    tar xjf "$1"     ;;
        *.tgz)     tar xzf "$1"     ;;
        *.zip)     unzip "$1"       ;;
        *.7z)      7z x "$1"        ;;
        *)         echo "Error: unsupported archive format '$1'" >&2; return 1 ;;
    esac
}

# ------------------------------------------------------------------------------
# 8. Plugins (Inline History Autosuggestions & Syntax Highlighting)
# ------------------------------------------------------------------------------
# Automatically loads system-installed plugins on Debian/Ubuntu, RHEL, or macOS.
# NOTE: zsh-syntax-highlighting MUST remain at the very end of .zshrc.

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

_zsh_plugin_paths=(
    "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
)
for _plugin in "${_zsh_plugin_paths[@]}"; do
    if [[ -r "$_plugin" ]]; then
        source "$_plugin"
        break
    fi
done

_zsh_hl_paths=(
    "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
)
for _plugin in "${_zsh_hl_paths[@]}"; do
    if [[ -r "$_plugin" ]]; then
        source "$_plugin"
        break
    fi
done
unset _plugin _zsh_plugin_paths _zsh_hl_paths

# ------------------------------------------------------------------------------
# 9. Local Machine Overrides (Not tracked in Git)
# ------------------------------------------------------------------------------
[[ -r "${ZDOTDIR:-$HOME}/.zshrc.local" ]] && source "${ZDOTDIR:-$HOME}/.zshrc.local"
