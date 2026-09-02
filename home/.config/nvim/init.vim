" ~/.config/nvim/init.vim — ~/.dotfiles/home/.config/nvim/init.vim руу symlink.

" vim-plug байхгүй бол өөрөө татна (шинэ машин дээрх хамгийн анхны ачаалалт).
let s:plug_path = stdpath('data') . '/site/autoload/plug.vim'
if empty(glob(s:plug_path))
  silent execute '!curl -fsSLo ' . shellescape(s:plug_path) . ' --create-dirs'
        \ . ' https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'

Plug 'ldelossa/nvim-ide'

Plug 'easymotion/vim-easymotion'

Plug 'flazz/vim-colorschemes'

Plug 'tpope/vim-fugitive'

Plug 'tpope/vim-surround'

Plug 'Shougo/vimproc.vim', {'do' : 'make'}

Plug 'Shougo/unite.vim'

Plug 'Shougo/vimfiler.vim'

Plug 'majutsushi/tagbar'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

Plug 'vim-airline/vim-airline'

Plug 'vim-airline/vim-airline-themes'

Plug 'preservim/nerdtree'
"Plug 'mortonfox/nerdtree-term'
"Plug 'tpope/vim-dadbod'
"Plug 'kristijanhusak/vim-dadbod-ui'
"Plug 'kristijanhusak/vim-dadbod-completion'
"
Plug 'nvim-treesitter/nvim-treesitter', {'branch': 'master', 'do': ':TSUpdate'}
Plug 'HiPhish/rainbow-delimiters.nvim'
Plug 'sainnhe/gruvbox-material'
Plug 'sainnhe/sonokai'
Plug 'rebelot/kanagawa.nvim'

" gd buyu eh function ruu shiljine
" nvim 0.11-ээс доош хувилбарт lspconfig нь vim.uv дээр унадаг (apt-ийн nvim
" ихэвчлэн 0.9). Тиймээс хуучин nvim дээр огт ачаалахгүй.
if has('nvim-0.11')
  Plug 'neovim/nvim-lspconfig'
endif
call plug#end() 

lua << EOF
-- Parser-ууд эх кодоос compile хийгддэг. C compiler байхгүй бол
-- treesitter файл нээх бүрт алдаа хэвлэдэг тул тэр үед автомат суулгацыг унтраана.
local has_cc = vim.fn.executable('cc') == 1
        or vim.fn.executable('gcc') == 1
        or vim.fn.executable('clang') == 1
require('nvim-treesitter.configs').setup({
	ensure_installed = has_cc and { 'java', 'xml', 'yaml', 'json', 'sql' } or {},
	highlight = { enable = true },
})

-- LSP: gd = go to definition (needs the language servers on PATH)
-- vim.lsp.enable() нь nvim 0.11+ дээр л байдаг.
if vim.fn.has('nvim-0.11') == 1 then
  vim.lsp.enable({ 'jdtls', 'ts_ls' })
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)
  end,
})
EOF


" copy
set clipboard=unnamedplus

" realtime auto changes with claude.
set autoread
autocmd FocusGained,BufEnter,CursorHold * checktime

" Basics {
syntax on
set ai
"set list
set hidden
set number
set listchars=tab:▸\ ,trail:·
"set hlsearch
set mouse=a
set nobackup
set termguicolors
set tabstop=4
set shiftwidth=4
set noswapfile
set cursorline
set visualbell t_vb=
"set laststatus=2
silent! color deus
"color sonokai
"color kanagawa

set nofixendofline

" }

" Bindings {
nmap ; :
let mapleader = ","
nnoremap <leader>b :Unite buffer<cr>
nnoremap <space>s :Unite -quick-match buffer<cr>
nnoremap <leader>ne :VimFilerExplorer -fnamewidth=0<cr>
" }

" Tab control bindings {
"-nnoremap <c-t> :tabnew<cr>
"nnoremap <leader>1 1gt
"nnoremap <leader>2 2gt
"nnoremap <leader>3 3gt
"nnoremap <leader>4 4gt
"nnoremap <leader>5 5gt
"nnoremap <leader>6 6gt
"nnoremap <leader>7 7gt
" }

" JSONView {
function JSONView()
        :%!python3 -m json.tool
        set filetype=json
endfunction
command JSONView :exec JSONView()
" }


call unite#custom#profile('default', 'context', {
\   'direction': 'botright',
\   'vertical_preview': 1,
\   'winheight': 15
\})

" Filetype specific configs {
command Input :execute "rightb vsp " . expand("%:p:h") . "/input.txt"
autocmd FileType cpp map <F9> :!g++ -std=c++14 -o "%:p:r" "%:p" && "%:p:r" < "%:p:h"/input.txt && rm "%:p:r"<cr>
"autocmd Filetype cpp setlocal et
autocmd Filetype xml setlocal sw=4 sts=4 et
autocmd Filetype java setlocal sw=4 sts=4 et
autocmd Filetype json setlocal sw=2 sts=2 et
autocmd Filetype php setlocal sw=2 sts=2 et " php
autocmd Filetype javascript setlocal sw=2 sts=2 et
" }

" FZF {
" Shell-д FZF_DEFAULT_COMMAND-ыг `ls` болгосон тул, :FZF-ийг рекурсив хэвээр нь
" үлдээхийн тулд nvim дотор нь хоослоно (хоосон бол fzf өөрийн walker-ээ хэрэглэнэ).
let $FZF_DEFAULT_COMMAND = ''

" :Browse — `ls` шиг ЗӨВХӨН нэг түвшин жагсаана.
" Фолдер дээр Enter → дотогш нь ордог, `..` → нэг шат ухарна, файл дээр → нээнэ.
function! s:browse_sink(dir, lines) abort
  if empty(a:lines) || empty(a:lines[0])
    return
  endif
  let l:sel = a:lines[0]
  let l:target = l:sel ==# '..' ? fnamemodify(a:dir, ':h') : a:dir . '/' . l:sel
  if isdirectory(l:target)
    " sink дотроос шууд fzf дуудвал болдоггүй тул нэг tick хойшлуулна
    call timer_start(10, {-> s:browse(l:target)})
  else
    execute 'edit ' . fnameescape(l:target)
  endif
endfunction

function! s:browse(dir) abort
  let l:dir = substitute(fnamemodify(a:dir, ':p'), '/$', '', '')
  if empty(l:dir)
    let l:dir = '/'
  endif
  let l:src = (l:dir ==# '/' ? '' : 'printf "..\n"; ')
        \ . 'command ls -A --group-directories-first'
  call fzf#run(fzf#wrap({
        \ 'source':  l:src,
        \ 'dir':     l:dir,
        \ 'options': ['--prompt', l:dir . '/ > ', '--no-multi'],
        \ 'sink*':   {lines -> s:browse_sink(l:dir, lines)},
        \ }))
endfunction
command! -nargs=? -complete=dir Browse call s:browse(empty(<q-args>) ? getcwd() : <q-args>)

nnoremap <c-p> :Browse<cr>
nnoremap <leader>p :FZF<cr>
" }

" Tagbar {
nnoremap <F8> :Tagbar<enter>
nnoremap <C-n> :NERDTree<enter>
" }

" VimAirline {
let g:airline#extensions#tabline#enabled = 1
" }

"autocmd VimEnter * NERDTree

imap jj <ESC>
"imap <C> <S>
"inoreab <buffer> e E
"nmap <C-a> <C-w>
