# shell/functions.zsh — fzf дээр суурилсан хөтчүүд.
# $DOT_LS / $DOT_BAT / $DOT_LS_ALWAYS нь env.zsh-д тодорхойлогдоно.

# fza = маш том мод дээр хурдан хайх (fzf-ийн built-in Go walker, find биш)
fza() { FZF_DEFAULT_COMMAND= command fzf "$@"; }

# fzg = ГЛОБАЛ хайлт. Хаанаас дуудсанаас үл хамааран $HOME (эсвэл өгсөн фолдер)
#       бүхэлд, БҮТЭН замаар хайна. fzf-ийн Go walker-ийг ашигладаг тул
#       find-ээс ~5 дахин хурдан асна.  Ж: fzg          → ~ бүхэлд
#                                          fzg ~/beta   → зөвхөн beta дотор
fzg() {
  local root=$HOME
  # эхний аргумент нь БАЙГАА фолдер бол түүнийг root болгоно, үгүй бол
  # бүх аргументыг fzf-рүү шууд дамжуулна (ж: fzg --preview-window=up).
  [[ -n $1 && -d ${1:A} ]] && { root=${1:A}; shift }
  FZF_DEFAULT_COMMAND= command fzf \
    --walker=file,dir,follow,hidden --walker-skip="$FZF_SKIP" \
    --walker-root="$root" --prompt="${root%/}/ > " "$@"
}

# ff = ЯГ ЭНЭ ФОЛДЕР-ыг л (`ls` шиг) харуулж, дотогш явж болдог browser.
#   enter / tab  : фолдер дээр бол ДОТОГШ орно, файл дээр бол замыг нь хэвлэнэ
#   ctrl-h / ..  : нэг шат УХАРНА
ff() {
  local base="${1:-$PWD}" dir out key sel target
  base=${base:A}
  dir=$base
  while true; do
    out=$(
      { [[ $dir != / ]] && print '..'
        command $DOT_LS -A --group-directories-first "$dir"
      } | command fzf \
            --expect=tab,ctrl-h \
            --prompt="${dir%/}/ > " \
            --header='enter/tab: орох · ctrl-h: ухрах · esc: гарах' \
            --preview "[ -d ${(q)dir}/{} ] && command $DOT_LS -la $DOT_LS_ALWAYS ${(q)dir}/{} || $DOT_BAT -n --color=always --line-range=:500 ${(q)dir}/{}"
    ) || return 0
    key=${out%%$'\n'*}
    sel=${out#*$'\n'}
    [[ $out == $key ]] && sel=''
    if [[ $key == ctrl-h ]]; then
      dir=${dir:h}
      continue
    fi
    [[ -z $sel ]] && return 0
    if [[ $sel == '..' ]]; then
      dir=${dir:h}
    elif [[ -d ${dir%/}/$sel ]]; then
      dir=${dir%/}/$sel
    else
      # Хуучин fzf шиг: эхэлсэн фолдероосоо ХАРЬЦАНГУЙ зам хэвлэнэ.
      # Дээшээ гарчихсан бол харьцангуй болгох боломжгүй тул бүтэн замаа хэвлэнэ.
      target=${dir%/}/$sel
      if [[ ${target[1,${#base}+1]} == "${base%/}/" ]]; then
        print -r -- "${target[${#base}+2,-1]}"
      else
        print -r -- "$target"
      fi
      return 0
    fi
  done
}

# fcd = ff-ээр фолдер сонгоод тэр фолдер уруу cd хийнэ (Enter-ийг фолдер дээр биш,
#       Ctrl-C-гүйгээр зогсоохын тулд одоогийн фолдероо сонгох `.` мөр нэмэв)
fcd() {
  local dir="${1:-$PWD}" sel
  dir=${dir:A}
  while true; do
    sel=$(
      { print '.'
        [[ $dir != / ]] && print '..'
        command $DOT_LS -A --group-directories-first "$dir" | while read -r x; do
          [[ -d $dir/$x ]] && print -r -- "$x"
        done
      } | command fzf --prompt="cd ${dir}/ > " \
            --preview "command $DOT_LS -la $DOT_LS_ALWAYS ${(q)dir}/{}"
    ) || return 0
    case $sel in
      ''|'.') builtin cd -- "$dir"; return 0 ;;
      '..')   dir=${dir:h} ;;
      *)      dir=$dir/$sel ;;
    esac
  done
}
