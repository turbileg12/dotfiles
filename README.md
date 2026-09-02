# dotfiles

Turbileg-ийн ажлын орчин: **zsh + oh-my-zsh + powerlevel10k, neovim, tmux, fzf**.
Шинэ Linux сервер, Ubuntu desktop, эсвэл Mac дээр **нэг мөрөөр** бүхэлд нь угсарна.

```sh
curl -fsSL https://raw.githubusercontent.com/turbileg12/dotfiles/main/bootstrap.sh | bash
```

Дараа нь `~/.zshrc.local` дотор token/нууц үгээ бөглөөд `exec zsh`.

---

## Флагууд

```sh
~/.dotfiles/bootstrap.sh --dry-run     # юу хийхээ хэвлэнэ, юу ч өөрчлөхгүй
~/.dotfiles/bootstrap.sh --server      # font, gnome-terminal-ыг албадан алгасах
~/.dotfiles/bootstrap.sh --desktop     # desktop гэж албадах
~/.dotfiles/bootstrap.sh --no-fonts
~/.dotfiles/bootstrap.sh --skip-brew   # package суулгацгүйгээр зөвхөн config
```

Скрипт нь **дахин дахин ажиллуулж болно**. Байгаа файлыг дарж бичихийн өмнө
`~/.dotfiles-backup/<timestamp>/` рүү зөөнө — юу ч алдагдахгүй.

Desktop эсэхийг `$DISPLAY`/`$WAYLAND_DISPLAY` болон `$SSH_CONNECTION`-оор өөрөө
таана. Сервер дээр font, `dconf`, gnome-terminal-ын профайл автоматаар алгасагдана.

## Юу орох вэ

| Зам | Тайлбар |
|---|---|
| `home/**` | `$HOME` руу symlink болох файлууд (`.zshrc`, `.tmux.conf`, `.p10k.zsh`, `.gitconfig`, `.config/nvim/init.vim`) |
| `shell/*.zsh` | `.zshrc`-ийн салангид хэсгүүд: `env` (PATH/brew/JAVA_HOME), `aliases`, `fzf`, `functions` |
| `bin/*` | `~/.local/bin` руу symlink: `tmux-clip`, `p10k-recustomize` |
| `fonts/fonts.conf` | fontconfig дүрэм (Linux) |
| `terminal/*.dconf` | gnome-terminal профайл |
| `Brewfile` | package жагсаалт |
| `templates/` | `~/.zshrc.local`-ын загвар |

## Font

Терминал: **Hack Nerd Font 12**.

Hack-д CJK glyph байхгүй тул Япон бичиг fallback-аар гардаг бөгөөд fontconfig нь
анхдагчаар `Noto Sans Mono CJK **KR**`-ыг сонгодог — ханз Солонгос хэлбэртэй
(直 画 骨 г.м. зурлага өөр) гарна. `fonts/fonts.conf` үүнийг **JP** руу засна.

```sh
fc-match -s 'monospace:lang=ja' | head -1     # → Noto Sans Mono CJK JP
printf '日本語 直画骨  ╭──╮  Монгол   \n'
```

Font солих бол `bootstrap.sh` дотор:

```sh
FONT_ASSET="JetBrainsMono"            # Nerd Fonts release дэх zip-ийн нэр
FONT_FAMILY="JetBrainsMono Nerd Font" # fontconfig / gnome-terminal-ын нэр
```

## Платформын ялгаа

| Зүйл | Linux | macOS |
|---|---|---|
| `find -printf`, `ls --group-directories-first` | төрөлх | `gfind` / `gls` (brew `findutils`, `coreutils`) — `shell/env.zsh` өөрөө сонгоно |
| Clipboard | `wl-copy` / `xclip` / `xsel` | `pbcopy` — `bin/tmux-clip` өөрөө таана |
| `JAVA_HOME` | `/usr/lib/jvm/java-21-*` | `/usr/libexec/java_home -v 21` |
| Homebrew | `/home/linuxbrew/...` | `/opt/homebrew` (ARM) эсвэл `/usr/local` (Intel) |
| fontconfig | ✅ | ⛔ CoreText, дүрэм алгасагдана |
| Терминалын профайл | `dconf` автоматаар | гараар (font-ын нэрийг хэвлэж өгнө) |

## Нууц зүйлс

Token, нууц үг **энэ repo-д хэзээ ч орохгүй**. Бүгд `~/.zshrc.local` дотор
(`.gitignore`-д), `~/.zshrc`-ийн хамгийн сүүлд source хийгддэг.
Загвар: `templates/zshrc.local.example`.

`~/.gitconfig` нь `~/.gitconfig.local`-ыг `[include]` хийдэг тул машин тус бүрд
өөр `user.email` тавьж болно.

## Powerlevel10k — АНХААР

`p10k configure` нь `~/.p10k.zsh`-г **нөөцгүйгээр бүрэн дарж бичдэг**. Энэ repo
дахь `.p10k.zsh` нь өөрчлөлт бүрийг нь агуулсан бэлэн хувилбар, тиймээс
`bootstrap.sh` нь wizard-ыг **огт дуудахгүй**. Хэрэв wizard-ыг ажиллуулах бол:

```sh
p10k configure
p10k-recustomize && exec zsh     # өөрчлөлтүүдийг буцааж түрхэнэ
```

## Шалгагдсан байдал

| Орчин | Төлөв |
|---|---|
| Ubuntu 24.04 (энэ машин, desktop) | ✅ |
| Ubuntu 24.04 цэвэр container (`--skip-brew`) | ✅ 19/19 шалгалт өнгөрсөн |
| Дахин ажиллуулалт (idempotent) | ✅ хоёр дахь удаад юу ч өөрчлөгдөхгүй |
| macOS дуураймал (`gfind`/`gls`/`pbcopy` shim) | ✅ хэрэгслээ зөв сонгож байна |
| macOS | ⚠️ **бодит Mac дээр хараахан ажиллуулж үзээгүй.** `gfind`/`gls`, `pbcopy`, `java_home` замууд код дотор бэлэн. Эхний удаа `--dry-run`-аар шалгаад ажиллуулна уу. |
