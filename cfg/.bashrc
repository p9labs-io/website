#!/usr/bin/env bash
# ==============================================================================
# Bootstrap: Bash Configuration
# ==============================================================================

# 1. Shell Options (Safe defaults)
# ------------------------------------------------------------------------------
shopt -s histappend      # Append history across tabs instead of overwriting
shopt -s checkwinsize    # Update LINES and COLUMNS after commands for proper redraws

# 2. History Settings
# ------------------------------------------------------------------------------
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=50000
HISTFILESIZE=100000
HISTTIMEFORMAT="[%F %T] "

# 3. Environment Variables (Placeholders)
# ------------------------------------------------------------------------------
# export EDITOR="vim"
# export VISUAL="vim"
# export PAGER="less"
# export LANG="en_US.UTF-8"
# export LC_ALL="en_US.UTF-8"
# export PATH="$HOME/.local/bin:$PATH"

# 4. Programmable Bash Completion
# ------------------------------------------------------------------------------
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    elif [ -f /opt/homebrew/etc/profile.d/bash_completion.sh ]; then
        . /opt/homebrew/etc/profile.d/bash_completion.sh
    elif [ -f /usr/local/etc/profile.d/bash_completion.sh ]; then
        . /usr/local/etc/profile.d/bash_completion.sh
    fi
fi

# 5. Terminal Colors & Prompt Styling
# ------------------------------------------------------------------------------
RESET='\[\e[0m\]'
BOLD='\[\e[1m\]'
FG_RED='\[\e[38;5;196m\]'
FG_GREEN='\[\e[38;5;76m\]'
FG_YELLOW='\[\e[38;5;220m\]'
FG_BLUE='\[\e[38;5;75m\]'
FG_GRAY='\[\e[38;5;244m\]'
FG_WHITE='\[\e[38;5;255m\]'

__prompt_git() {
    command -v git >/dev/null 2>&1 || return
    local branch dirty=""
    
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [[ -z "$branch" ]] && return

    if ! git diff --quiet --ignore-submodules HEAD -- 2>/dev/null; then
        dirty="*"
    fi

    if [[ -n "$dirty" ]]; then
        printf " ${FG_YELLOW}(git:${branch}${dirty})${RESET}"
    else
        printf " ${FG_GREEN}(git:${branch})${RESET}"
    fi
}

__build_prompt() {
    local EXIT_CODE=$?
    
    local status_indicator
    if [[ $EXIT_CODE -eq 0 ]]; then
        status_indicator="${FG_GREEN}✔${RESET}"
    else
        status_indicator="${FG_RED}✘ ${EXIT_CODE}${RESET}"
    fi

    local meta="${FG_GRAY}[\D{%T}]${RESET} ${FG_BLUE}\u@\h${RESET}"
    local dir="${FG_WHITE}${BOLD}\w${RESET}"
    local git_info=$(__prompt_git)

    PS1="\n${meta} ${dir}${git_info}\n${status_indicator} ${BOLD}\$${RESET} "
}

PROMPT_COMMAND=__build_prompt

# 6. User Added Configuration (Aliases, Functions, Tool Overrides)
# ------------------------------------------------------------------------------
# alias ll='ls -lah --color=auto'
# alias grep='grep --color=auto'
# alias g='git'

# 7. Machine-Specific Overrides (Optional / Untracked)
# ------------------------------------------------------------------------------
# Loads machine-specific secrets, work tokens, or local path overrides if present
if [[ -f "$HOME/.bashrc.local" ]]; then
    . "$HOME/.bashrc.local"
fi

