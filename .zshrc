# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
. ~/.config/aliasrc

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="avit"
set -o vi

plugins=(z command-time zsh-autosuggestions fzf)

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#99aaae"
export ANDROID_HOME=/home/tobins/Android/Sdk
export CHROME_EXECUTABLE=/bin/google-chrome-stable
export PATH=$PATH:$ANDROID_HOME/tools 
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH/:$ANDROID_HOME/platform-tools
export PATH=$PATH/:$ANDROID_HOME/platform-tools
export PATH=$PATH:$HOME/.scripts

# Enable Ctrl-x-e to edit command line
autoload -U edit-command-line
# Emacs style
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line
eval $(thefuck --alias)
# Vi style:
#zle -N edit-command-line
#bindkey -M vicmd v edit-command-line

source $ZSH/oh-my-zsh.sh
