# ~/.zshrc — ~/.dotfiles/home/.zshrc руу symlink.
# Машин-тусгай зүйл (token, нууц үг) ЭНД БИЧИХГҮЙ → ~/.zshrc.local руу.

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# PATH / Homebrew / JAVA_HOME / GNU tool detection (oh-my-zsh-ээс ӨМНӨ)
source "$DOTFILES/shell/env.zsh"

# --- oh-my-zsh -----------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# --- өөрийн тохиргоо -----------------------------------------------------
source "$DOTFILES/shell/aliases.zsh"
source "$DOTFILES/shell/fzf.zsh"
source "$DOTFILES/shell/functions.zsh"

# --- nvm -----------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                    # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # nvm completion

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# АНХААР: `p10k configure` нь ~/.p10k.zsh-г нөөцгүйгээр дарж бичдэг. Дараа нь
# `p10k-recustomize && exec zsh` ажиллуулж өөрчлөлтүүдээ буцааж түрхэнэ.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- машин-тусгай (git-д ОРОХГҮЙ) ---------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
