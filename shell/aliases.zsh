# shell/aliases.zsh

alias lss="command $DOT_LS -tr"

# colorls бол ruby gem — байхгүй машин олон. Байвал л ашиглана, үгүй бол
# энгийн өнгөт ls рүү уналттай (өмнө нь байхгүй үед `ls` бүрэн эвдэрдэг байсан).
if command -v colorls >/dev/null 2>&1; then
  alias ls='colorls -tr'
else
  alias ls="command $DOT_LS -tr $DOT_LS_COLOR"
fi
