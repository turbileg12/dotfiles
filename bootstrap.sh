#!/usr/bin/env bash
#
# bootstrap.sh — ГАНЦ ФАЙЛ. Шинэ машин дээр бүх ажлын орчныг угсарна.
#
#   curl -fsSL https://raw.githubusercontent.com/turbileg12/dotfiles/main/bootstrap.sh | bash
#
# эсвэл repo-г clone хийчихсэн бол:
#
#   ~/.dotfiles/bootstrap.sh [флаг...]
#
# Флагууд:
#   --dry-run     Юу хийхээ хэвлээд, юу ч ӨӨРЧЛӨХГҮЙ
#   --server      Desktop-ын зүйлсийг албадан алгасах (font, dconf)
#   --desktop     Desktop гэж албадах (font, dconf-ыг заавал хийх)
#   --no-fonts    Зөвхөн font суулгацыг алгасах
#   --skip-brew   Homebrew болон package суулгацыг алгасах
#   -h | --help
#
# Дахин дахин ажиллуулж болно (idempotent). Байгаа файлыг дарж бичихийн өмнө
# ~/.dotfiles-backup/<timestamp>/ рүү зөөнө.

set -euo pipefail

# ---------------------------------------------------------------- тохиргоо --
REPO_URL="${DOTFILES_REPO:-https://github.com/turbileg12/dotfiles.git}"
REPO_BRANCH="${DOTFILES_BRANCH:-main}"
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# Font солих бол ГАНЦ ЭНЭ ХОЁР МӨР. Нэр нь Nerd Fonts release-ийн asset-ийн
# нэр (Hack.zip → "Hack"), FONT_FAMILY нь fontconfig/gnome-terminal-ын нэр.
FONT_ASSET="${FONT_ASSET:-Hack}"
FONT_FAMILY="${FONT_FAMILY:-Hack Nerd Font}"
FONT_SIZE="${FONT_SIZE:-12}"

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# ------------------------------------------------------------------ флагууд --
DRY_RUN=0; FORCE_PROFILE=""; DO_FONTS=1; DO_BREW=1
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=1 ;;
    --server)    FORCE_PROFILE=server ;;
    --desktop)   FORCE_PROFILE=desktop ;;
    --no-fonts)  DO_FONTS=0 ;;
    --skip-brew) DO_BREW=0 ;;
    -h|--help)   sed -n '2,25p' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Танихгүй флаг: $arg (--help үзнэ үү)" >&2; exit 2 ;;
  esac
done

# ----------------------------------------------------------------- логчид ----
if [[ -t 1 ]]; then
  C_B=$'\033[1m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_D=$'\033[2m'; C_0=$'\033[0m'
else
  C_B=""; C_G=""; C_Y=""; C_R=""; C_D=""; C_0=""
fi
STEP=0
step() { STEP=$((STEP+1)); printf '\n%s[%02d] %s%s\n' "$C_B" "$STEP" "$*" "$C_0"; }
ok()   { printf '  %s✓%s %s\n' "$C_G" "$C_0" "$*"; }
skip() { printf '  %s·%s %s\n' "$C_D" "$C_0" "$*"; SKIPPED+=("$*"); }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_0" "$*"; WARNINGS+=("$*"); }
die()  { printf '\n%sАЛДАА:%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }
run()  {
  if (( DRY_RUN )); then printf '  %s[dry-run]%s %s\n' "$C_D" "$C_0" "$*"; return 0; fi
  "$@"
}
SKIPPED=(); WARNINGS=(); FC_FAMILIES=""

have() { command -v "$1" >/dev/null 2>&1; }

# --------------------------------------------------- 0. орчноо тодорхойлох --
step "Орчноо тодорхойлж байна"

case "$(uname -s)" in
  Darwin) OS=mac ;;
  Linux)  OS=linux ;;
  *)      die "Дэмжигдээгүй систем: $(uname -s)" ;;
esac
ARCH="$(uname -m)"

if [[ -n $FORCE_PROFILE ]]; then
  PROFILE=$FORCE_PROFILE
elif [[ $OS == mac ]]; then
  PROFILE=desktop                     # Mac дээр SSH-ээр орсон ч GUI байдаг
elif [[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]]; then
  PROFILE=desktop
else
  PROFILE=server
fi
if [[ $PROFILE == server ]]; then DO_FONTS=0; fi

ok "OS=$OS  arch=$ARCH  profile=$PROFILE$( ((DRY_RUN)) && echo '  (DRY RUN)' )"

# sudo байгаа эсэх (сервер дээр ихэвчлэн байхгүй)
SUDO=""
if [[ $EUID -ne 0 ]] && have sudo && sudo -n true 2>/dev/null; then
  SUDO="sudo"
elif [[ $EUID -eq 0 ]]; then
  SUDO=""
fi

# ------------------------------------------------------- 1. git / curl ------
step "Үндсэн хэрэгслүүд (git, curl)"
install_prereq() {
  local missing=()
  have git  || missing+=(git)
  have curl || missing+=(curl)
  if (( ${#missing[@]} == 0 )); then ok "git, curl аль хэдийн байна"; return; fi

  if [[ $OS == mac ]]; then
    have git || { warn "Xcode CLI tools хэрэгтэй: xcode-select --install"; run xcode-select --install || true; }
  elif have apt-get; then
    [[ -n $SUDO || $EUID -eq 0 ]] || die "${missing[*]} байхгүй бөгөөд sudo ч алга. Гараар суулгана уу."
    run $SUDO apt-get update -qq
    run $SUDO apt-get install -y -qq "${missing[@]}"
  elif have dnf; then
    run $SUDO dnf install -y "${missing[@]}"
  elif have yum; then
    run $SUDO yum install -y "${missing[@]}"
  elif have apk; then
    run $SUDO apk add --no-cache "${missing[@]}"
  else
    die "${missing[*]} байхгүй, package manager танигдсангүй."
  fi
  ok "суулгав: ${missing[*]}"
}
install_prereq

# --------------------------------------------- 2. repo (curl|bash горим) ----
step "Dotfiles repo"
SELF="${BASH_SOURCE[0]:-}"
SELF_DIR=""
if [[ -f $SELF ]]; then SELF_DIR="$(cd "$(dirname "$SELF")" && pwd)"; fi

if [[ -z $SELF_DIR || ! -d $SELF_DIR/home ]]; then
  # curl | bash — локал хуулбар байхгүй. Clone хийж, өөрийгөө дахин дуудна.
  if [[ -n ${DOT_BOOTSTRAP_REEXEC:-} ]]; then die "Дахин дуудалт давхарлаа — $DOTFILES эвдэрсэн байж магадгүй."; fi
  if [[ -d $DOTFILES/.git ]]; then
    ok "$DOTFILES байна — шинэчилж байна"
    run git -C "$DOTFILES" pull --ff-only origin "$REPO_BRANCH" || warn "git pull амжилтгүй, байгаагаар нь үргэлжлүүлнэ"
  else
    ok "clone: $REPO_URL → $DOTFILES"
    run git clone --branch "$REPO_BRANCH" "$REPO_URL" "$DOTFILES"
  fi
  if (( DRY_RUN )); then echo; echo "[dry-run] цааш нь $DOTFILES/bootstrap.sh $* ажиллах байсан."; exit 0; fi
  export DOT_BOOTSTRAP_REEXEC=1
  exec bash "$DOTFILES/bootstrap.sh" "$@"
fi

if [[ $SELF_DIR != "$DOTFILES" ]]; then
  warn "Repo нь $SELF_DIR дотор байна ($DOTFILES биш). Түүнийг л ашиглана."
  DOTFILES="$SELF_DIR"
fi
ok "repo: $DOTFILES"

# ------------------------------------------------------- 3. Homebrew --------
step "Homebrew"
brew_shellenv() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew \
           /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [[ -x $b ]]; then eval "$("$b" shellenv)"; return 0; fi
  done
  return 1
}
if (( ! DO_BREW )); then
  skip "Homebrew (--skip-brew)"
elif brew_shellenv; then
  ok "Homebrew байна: $(command -v brew)"
else
  ok "Homebrew суулгаж байна"
  run bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  brew_shellenv || warn "Homebrew суусан ч PATH-д олдсонгүй. Terminal-аа дахин нээгээд ахин ажиллуулна уу."
fi

# --------------------------------------------------------- 4. packages ------
step "Packages (Brewfile)"
if (( ! DO_BREW )); then
  skip "brew bundle (--skip-brew)"
elif have brew; then
  run brew bundle --file="$DOTFILES/Brewfile" || warn "brew bundle бүрэн дуусаагүй — дээрх алдааг үзнэ үү"
  ok "Brewfile боловсруулав"
else
  warn "brew байхгүй тул package суулгацыг алгаслаа"
fi

# ------------------------------------------------------- 5. oh-my-zsh -------
step "oh-my-zsh + powerlevel10k"
ZSH_DIR="$HOME/.oh-my-zsh"
if [[ -d $ZSH_DIR ]]; then
  ok "oh-my-zsh байна"
else
  run bash -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  ok "oh-my-zsh суулгав"
fi
P10K_DIR="$ZSH_DIR/custom/themes/powerlevel10k"
if [[ -d $P10K_DIR/.git ]]; then
  ok "powerlevel10k байна"
else
  run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  ok "powerlevel10k суулгав"
fi

# ---------------------------------------------------------- 6. symlink ------
step "Config файлуудыг холбож байна"
link() {                       # link <эх зам> <очих зам>
  local src="$1" dst="$2"
  if [[ -L $dst && "$(readlink "$dst")" == "$src" ]]; then
    ok "${dst/#$HOME/\~} (аль хэдийн холбоотой)"; return
  fi
  if [[ -e $dst || -L $dst ]]; then
    run mkdir -p "$BACKUP_DIR/$(dirname "${dst#$HOME/}")"
    run mv "$dst" "$BACKUP_DIR/${dst#$HOME/}"
    warn "${dst/#$HOME/\~} → нөөцөд зөөв"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  ok "${dst/#$HOME/\~} → ${src/#$HOME/\~}"
}

while IFS= read -r rel; do
  link "$DOTFILES/home/$rel" "$HOME/$rel"
done < <(cd "$DOTFILES/home" && find . -type f | sed 's|^\./||')

# bin/ доторх скриптүүд
run mkdir -p "$HOME/.local/bin"
for f in "$DOTFILES"/bin/*; do
  [[ -f $f ]] || continue
  link "$f" "$HOME/.local/bin/$(basename "$f")"
done

# ------------------------------------------------------------- 7. fonts -----
step "Font"
if (( ! DO_FONTS )); then
  skip "Font (profile=$PROFILE эсвэл --no-fonts)"
else
  if [[ $OS == mac ]]; then FONT_DIR="$HOME/Library/Fonts"; else FONT_DIR="$HOME/.local/share/fonts"; fi
  # ЖИЧ: `fc-list | grep -q` гэж БИЧИХГҮЙ — grep -q эхний олдоцонд гарахад
  # fc-list SIGPIPE аваад 141 буцаадаг, `set -o pipefail` дор энэ нь бүтэлгүйтэл
  # мэт харагдана. Тиймээс эхлээд хувьсагч руу уншина.
  FC_FAMILIES=""
  if have fc-list; then FC_FAMILIES="$(fc-list : family 2>/dev/null || true)"; fi
  if [[ -n "$(ls "$FONT_DIR"/${FONT_ASSET}NerdFont*.ttf 2>/dev/null)" ]] \
     || grep -qF "$FONT_FAMILY" <<<"$FC_FAMILIES"; then
    ok "$FONT_FAMILY аль хэдийн суусан"
  else
    tmp="$(mktemp -d)"
    ok "$FONT_ASSET Nerd Font татаж байна"
    if run curl -fsSL -o "$tmp/font.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_ASSET}.zip"; then
      run mkdir -p "$FONT_DIR"
      run unzip -qo "$tmp/font.zip" -d "$FONT_DIR" -x 'LICENSE*' 'README*' '*.md'
      if have fc-cache; then run fc-cache -f "$FONT_DIR" >/dev/null; fi
      ok "$FONT_FAMILY → ${FONT_DIR/#$HOME/\~}"
    else
      warn "Font татаж чадсангүй (сүлжээ?). Гараар: nerdfonts.com"
    fi
    rm -rf "$tmp"
  fi

  # fontconfig дүрэм — зөвхөн Linux (macOS CoreText нь fontconfig уншдаггүй)
  if [[ $OS == linux ]]; then
    link "$DOTFILES/fonts/fonts.conf" "$HOME/.config/fontconfig/conf.d/50-turbileg.conf"
    # Япон CJK байхгүй бол дүрэм утгагүй — суулгахыг оролдоно.
    if have fc-list; then FC_FAMILIES="$(fc-list : family 2>/dev/null || true)"; fi
    if [[ -n $FC_FAMILIES ]] && ! grep -qF 'Noto Sans Mono CJK JP' <<<"$FC_FAMILIES"; then
      if have apt-get && [[ -n $SUDO || $EUID -eq 0 ]]; then
        if run $SUDO apt-get install -y -qq fonts-noto-cjk; then ok "fonts-noto-cjk суулгав"; else warn "fonts-noto-cjk суулгаж чадсангүй"; fi
      else
        warn "Noto CJK JP байхгүй — Япон бичиг зөв гарахгүй. Суулгах: apt install fonts-noto-cjk"
      fi
    fi
    if have fc-cache; then run fc-cache -f >/dev/null; fi
    ok "fontconfig дүрэм суув (Япон ханз JP хэлбэрээр)"
  fi
fi

# -------------------------------------------------------------- 8. nvim -----
step "Neovim"
if have nvim; then
  PLUG="$HOME/.local/share/nvim/site/autoload/plug.vim"
  if [[ -f $PLUG ]]; then
    ok "vim-plug байна"
  else
    run curl -fsSLo "$PLUG" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug суулгав"
  fi
  run nvim --headless '+PlugInstall --sync' +qa 2>/dev/null || warn "PlugInstall бүрэн дуусаагүй"
  ok "nvim plugin-ууд суув"
  run nvim --headless '+TSUpdateSync' +qa 2>/dev/null || warn "TSUpdate алгасагдав (compiler байхгүй байж болно)"
else
  warn "nvim байхгүй тул plugin суулгацыг алгаслаа"
fi

# -------------------------------------------------------------- 9. tmux -----
step "tmux"
TPM="$HOME/.tmux/plugins/tpm"
if [[ -d $TPM/.git ]]; then
  ok "tpm байна"
else
  run git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM"
  ok "tpm суулгав"
fi
if [[ -x $TPM/bin/install_plugins ]]; then
  run "$TPM/bin/install_plugins" >/dev/null 2>&1 || warn "tmux plugin суулгац бүрэн болсонгүй (prefix+I гараар дарж болно)"
  ok "tmux plugin-ууд суув"
fi
CLIP_BIN="$HOME/.local/bin/tmux-clip"; [[ -x $CLIP_BIN ]] || CLIP_BIN="$DOTFILES/bin/tmux-clip"
CLIP_INFO="$("$CLIP_BIN" which 2>/dev/null || true)"
ok "clipboard backend: ${CLIP_INFO%%$'\n'*}"

# ------------------------------------------------------ 10. terminal --------
step "Терминалын профайл"
if [[ $PROFILE == desktop && $OS == linux ]] && have dconf && have gsettings; then
  if run dconf load /org/gnome/terminal/ < "$DOTFILES/terminal/gnome-terminal.dconf"; then
    # `| head -1` биш `grep -m1`: pipefail дор head нь grep-д SIGPIPE өгдөг.
    PROF_UUID="$(grep -m1 -o '[0-9a-f-]\{36\}' "$DOTFILES/terminal/gnome-terminal.dconf" || true)"
    if [[ -n $PROF_UUID ]]; then
      run gsettings set org.gnome.Terminal.ProfilesList list "['$PROF_UUID']"
      run gsettings set org.gnome.Terminal.ProfilesList default "'$PROF_UUID'"
    fi
    ok "gnome-terminal: font, өнгө, тунгалаг байдал сэргээв"
  else
    warn "dconf load амжилтгүй"
  fi
elif [[ $OS == mac ]]; then
  echo "     Terminal.app / iTerm2 дээр font-оо гараар сонгоно уу:"
  echo "       ${C_B}${FONT_FAMILY} ${FONT_SIZE}${C_0}"
  skip "Mac дээр терминалын профайл автоматаар тохируулагдахгүй"
else
  skip "Терминалын профайл (profile=$PROFILE)"
fi

# ------------------------------------------------------ 11. login shell -----
step "Login shell"
ZSH_BIN="$(command -v zsh || true)"
if [[ -z $ZSH_BIN ]]; then
  warn "zsh байхгүй"
elif [[ "$(basename "${SHELL:-}")" == zsh ]]; then
  # Login shell аль хэдийн zsh бол ХҮРЭХГҮЙ. brew-ийн zsh рүү солих нь эрсдэлтэй:
  # /etc/shells-д байдаггүй бөгөөд Homebrew-гүй үед нэвтрэлт бүтэлгүйтэж болно.
  ok "zsh аль хэдийн login shell (${SHELL:-})"
else
  if ! grep -qxF "$ZSH_BIN" /etc/shells 2>/dev/null; then
    if [[ -n $SUDO || $EUID -eq 0 ]]; then
      run bash -c "echo '$ZSH_BIN' | $SUDO tee -a /etc/shells >/dev/null" || true
    fi
  fi
  if run chsh -s "$ZSH_BIN" 2>/dev/null; then
    ok "login shell → $ZSH_BIN (дараагийн нэвтрэлтээс эхэлнэ)"
  else
    warn "chsh амжилтгүй. Гараар: chsh -s $ZSH_BIN"
  fi
fi

# --------------------------------------------------------- 12. secrets ------
step "Машин-тусгай тохиргоо"
# shellcheck disable=SC2088  # доорх `~` нь зам биш, дэлгэцэнд харуулах текст
if [[ -f $HOME/.zshrc.local ]]; then
  ok "~/.zshrc.local байна"
else
  run cp "$DOTFILES/templates/zshrc.local.example" "$HOME/.zshrc.local"
  run chmod 600 "$HOME/.zshrc.local"
  warn "~/.zshrc.local үүсгэв — token/нууц үгээ БӨГЛӨНӨ ҮҮ"
fi

# ----------------------------------------------------------- 13. дүгнэлт ----
printf '\n%s%s%s\n' "$C_B" "════════════════════════════════════════════════════" "$C_0"
if (( DRY_RUN )); then
  printf '%sDRY RUN дууслаа — юу ч өөрчлөгдөөгүй.%s\n' "$C_Y" "$C_0"
else
  printf '%sБэлэн.%s  OS=%s  profile=%s\n' "$C_G" "$C_0" "$OS" "$PROFILE"
fi
if (( ${#SKIPPED[@]}  )); then echo; echo "Алгасав:";     printf '  · %s\n' "${SKIPPED[@]}";  fi
if (( ${#WARNINGS[@]} )); then echo; echo "Анхаарах нь:"; printf '  ! %s\n' "${WARNINGS[@]}"; fi
if [[ -d $BACKUP_DIR ]];   then echo; echo "Хуучин файлууд: ${BACKUP_DIR/#$HOME/\~}";           fi
cat <<EOF

Дараагийн алхам:
  1. ~/.zshrc.local дотор MAVEN_PASSWORD / NEXUS_TOKEN-оо бөглөх
  2. exec zsh          (эсвэл терминалаа дахин нээх)
  3. tmux дотор prefix + I  (plugin дутуу бол)

Шалгах:
  fc-match -s 'monospace:lang=ja' | head -1   → Noto Sans Mono CJK JP
  printf '日本語 直画骨  ╭──╮  Монгол   \\n'
EOF
