# Brewfile — `brew bundle --file=Brewfile`. macOS + Linuxbrew хоёуланд ажиллана.

brew "git"
brew "curl"
brew "zsh"
brew "neovim"
brew "tmux"
brew "fzf"
brew "bat"
brew "ripgrep"
brew "fd"
brew "jq"
brew "tree"
brew "htop"

if OS.mac?
  # ЗААВАЛ: shell/fzf.zsh, shell/functions.zsh нь GNU find/ls-ийн
  # `-printf`, `--group-directories-first` флагуудыг ашигладаг. Эдгээр нь
  # gfind / gls нэрээр ирнэ; env.zsh өөрөө тэднийг олж хэрэглэнэ.
  brew "coreutils"
  brew "findutils"
  brew "gnu-sed"
end

if OS.linux?
  # nvim-treesitter parser-уудаа эндээс compile хийнэ.
  brew "gcc"
end
