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

source $ZSH/oh-my-zsh.sh
