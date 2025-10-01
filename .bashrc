# Clean, human-readable bash prompt (no colors to avoid escape sequence issues)
# Shows: user@host:path (git-branch)>

# Function to get git branch
function parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Simple, clean prompt without color codes
# Colorized bash prompt - human readable with color variables
# Shows: user@host:path (git-branch)>
# Colors: Green for user@host, Blue for path, Yellow for git branch

# Define colors for readability
GREEN='\[\033[01;32m\]'
YELLOW='\[\033[01;33m\]'
BLUE='\[\033[01;34m\]'
MAGENTA='\[\033[01;35m\]'
RESET='\[\033[00m\]'

# Function to get git branch
function parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Clean, readable prompt definition using color variables
# Colors: Green for user, Yellow for host, Blue for path, Magenta for git branch
export PS1="${GREEN}\u${RESET}@${YELLOW}\h${RESET}:${BLUE}\w${MAGENTA}\$(parse_git_branch)${RESET}> "

# Alternative even simpler prompt showing just the upstream push info:
# export PS1='$(parse_git_branch)> '

# Enable color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Some useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'