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

# nvim-ийн LSP: init.vim дэх `vim.lsp.enable({'jdtls','ts_ls'})` эдгээрийг
# PATH дээр байхыг шаарддаг. Байхгүй бол `gd` (тодорхойлолт руу үсрэх) ажиллахгүй.
# tagbar (<F8>) нь ctags-гүйгээр "Exuberant ctags not found!" гэж унадаг.
brew "universal-ctags"

brew "jdtls"
brew "typescript-language-server"

if OS.mac?
  # ЗААВАЛ: shell/fzf.zsh, shell/functions.zsh нь GNU find/ls-ийн
  # `-printf`, `--group-directories-first` флагуудыг ашигладаг. Эдгээр нь
  # gfind / gls нэрээр ирнэ; env.zsh өөрөө тэднийг олж хэрэглэнэ.
  brew "coreutils"
  brew "findutils"
  brew "gnu-sed"
end

if OS.linux?
  # ЖИЧ: brew-ийн gcc нь ЗӨВХӨН `gcc-16` гэх хувилбартай нэр өгдөг — treesitter
  # нь `cc`/`gcc`/`clang` хайдаг тул үүнийг дангаар нь ОЛОХГҮЙ. Жинхэнэ шийдлийг
  # bootstrap.sh-ийн `ensure_cc` хийнэ (build-essential эсвэл $CC). Энэ нь нөөц.
  brew "gcc"
  brew "make"
end
