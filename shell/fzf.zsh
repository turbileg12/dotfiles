# shell/fzf.zsh — fzf-ийн хувьсагчид.
# find/ls-ийн GNU-only флагуудыг $DOT_FIND / $DOT_LS-ээр дамжуулна (env.zsh-д
# тодорхойлогдоно): Linux дээр find/ls, macOS дээр brew-ийн gfind/gls.

# Алгасах фолдерууд. ЛОКАЛ, ГЛОБАЛ, walker гурав нэг эх сурвалжаас уншина.
FZF_SKIP=".git,node_modules,.cache,.npm"
# find-ийн prune хэсэг. Хаалт \( \) ЗОРИУДААР ашиглаагүй: fzf-ийн reload(...) нь
# хаалтыг тоолж задалдаг тул хаалттай бол доорх --bind дотор эвдэрнэ.
_FZF_PRUNE="-name ${FZF_SKIP//,/ -prune -o -name } -prune -o"

# ЛОКАЛ = одоогийн фолдер (өмнөх зан төлөв яг хэвээрээ).
# ФОЛДЕРУУД БҮГД ДЭЭР, дараа нь ФАЙЛУУД БҮГД ДООР, хоёулаа ГҮНЭЭР нь эрэмбэлнэ
# (top-level asc/, beta-be/, ... эхэлж гарч, дараа нь тэдгээрийн дэд агуулга).
export FZF_LOCAL_CMD="$DOT_FIND . -mindepth 1 $_FZF_PRUNE -type d -printf \"%d\t%P/\n\" | sort -n -k1,1 -k2 | cut -f2- ; $DOT_FIND . $_FZF_PRUNE -type f -printf \"%d\t%P\n\" | sort -n -k1,1 -k2 | cut -f2-"

# ГЛОБАЛ = $HOME бүхэлд, БҮТЭН (absolute) зам хэвлэнэ. Тиймээс хаана зогсож
# байхаас үл хамааран сонгосон зам нь preview, cd, vim бүгдэд шууд ажиллана.
# Эрэмбэлэхгүй: 140мянга+ мөрийг fzf-рүү шууд урсгах нь sort хүлээхээс хурдан.
export FZF_GLOBAL_CMD="$DOT_FIND $HOME $_FZF_PRUNE -print"

# fzf нь эдгээрийг шинэ ($SHELL -c) shell-д ажиллуулдаг тул энд функцийн НЭР биш,
# бүтэн команд шууд бичигдэнэ (.zshrc-г дахин sourc-лохгүй).
export FZF_DEFAULT_COMMAND="$FZF_LOCAL_CMD"

# Хайлт дээрээ, preview (код) доороо
export FZF_DEFAULT_OPTS="
  --walker=file,dir,follow --walker-skip=$FZF_SKIP
  --height=90% --layout=reverse --info=inline --border=double --margin=1 --padding=1
  --preview '[ -d {} ] && $DOT_LS -la $DOT_LS_ALWAYS {} || $DOT_BAT -n --color=always --line-range=:500 {}'
  --preview-window=down:80%:wrap:border-top
  --header 'ctrl-g: ~ БҮХЭЛД хайх · ctrl-o: энэ фолдер руу буцах · ctrl-/: preview'
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:replace-query'
  --bind 'ctrl-g:reload($FZF_GLOBAL_CMD)+change-prompt(~ бүхэлд > )'
  --bind 'ctrl-o:reload($FZF_LOCAL_CMD)+change-prompt(> )'
  --bind 'ctrl-t:transform-query:x={}; case \$x in */) printf %s \$x ;; *) [ -d \$x ] && printf %s/ \$x || printf %s \$x ;; esac'
  --color=border:#FF69B4,preview-border:#7FFFD4,label:#88c0d0,bg+:#3c3836,bg:#32302f,spinner:#fb4934,hl:#928374,fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934,marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934
  "
