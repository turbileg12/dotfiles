# shell/env.zsh — PATH, Homebrew, JAVA_HOME. Платформ бүрт өөрөө тааруулна.
# Энэ файлыг oh-my-zsh ачаалахаас ӨМНӨ source хийнэ.

export PATH="$HOME/.local/bin:$PATH"

# --- Homebrew ------------------------------------------------------------
# Apple Silicon → Intel Mac → системийн Linuxbrew → хэрэглэгчийн Linuxbrew.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew \
             /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [[ -x $_brew ]]; then
    eval "$($_brew shellenv zsh)"
    break
  fi
done
unset _brew

# --- GNU хэрэгслүүд ------------------------------------------------------
# macOS-ийн BSD find/ls нь `-printf`, `--group-directories-first`-ыг мэдэхгүй.
# brew-ийн coreutils/findutils нь тэдгээрийг g- угтвартайгаар өгдөг.
# fzf.zsh, functions.zsh хоёр эдгээр хувьсагчийг ашиглана.
if command -v gfind >/dev/null 2>&1; then DOT_FIND=gfind; else DOT_FIND=find; fi
if command -v gls   >/dev/null 2>&1; then DOT_LS=gls;     else DOT_LS=ls;     fi
# Debian/Ubuntu-гийн apt дээр `bat` нь `batcat` нэртэй.
if   command -v bat    >/dev/null 2>&1; then DOT_BAT=bat
elif command -v batcat >/dev/null 2>&1; then DOT_BAT=batcat
else DOT_BAT=cat
fi
export DOT_FIND DOT_LS DOT_BAT

# BSD ls нь `--color`-ыг мэдэхгүй, `-G` хэрэглэдэг. Аль нь ажиллахыг нэг л удаа шалгана.
if $DOT_LS --color=auto -d . >/dev/null 2>&1; then
  DOT_LS_COLOR='--color=auto'; DOT_LS_ALWAYS='--color=always'
else
  DOT_LS_COLOR='-G';           DOT_LS_ALWAYS='-G'
fi
export DOT_LS_COLOR DOT_LS_ALWAYS

# --- Java ----------------------------------------------------------------
# Байхгүй бол чимээгүй алгасана: буруу JAVA_HOME нь PATH-ыг эвддэг.
if [[ -z ${JAVA_HOME:-} ]]; then
  if [[ -x /usr/libexec/java_home ]]; then                     # macOS
    JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null) || JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
  else                                                          # Linux
    for _jdk in /usr/lib/jvm/java-21-openjdk*(N) /usr/lib/jvm/java-21*(N) \
                /usr/lib/jvm/default-java(N); do
      [[ -d $_jdk ]] && { JAVA_HOME=$_jdk; break }
    done
    unset _jdk
    # brew-ийн openjdk (Linuxbrew дээр ч ажиллана)
    [[ -z ${JAVA_HOME:-} && -n ${HOMEBREW_PREFIX:-} && -d $HOMEBREW_PREFIX/opt/openjdk ]] \
      && JAVA_HOME=$HOMEBREW_PREFIX/opt/openjdk
  fi
fi
if [[ -n ${JAVA_HOME:-} && -d $JAVA_HOME ]]; then
  export JAVA_HOME
  export PATH="$JAVA_HOME/bin:$PATH"
else
  unset JAVA_HOME
fi
