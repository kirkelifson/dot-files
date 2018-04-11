" Plugins
filetype off
set nocompatible " helps if testing this vimrc using $ vim -u vimrc_file
set runtimepath+=~/.vim/bundle/vundle
call vundle#begin()
Plugin 'VundleVim/Vundle.vim' " required
Plugin 'scrooloose/nerdtree' " file system explorer
Plugin 'kien/ctrlp.vim' " fuzzy file, buf finder
Plugin 'ervandew/supertab' " tab completion
Plugin 'sjl/badwolf' " main colorscheme
Plugin 'reedes/vim-colors-pencil' " goyo colorscheme
Plugin 'junegunn/goyo.vim' " distraction-free writing
call vundle#end()
filetype plugin indent on

" Whitespace
set expandtab " converts tabs to spaces
set autoindent

" Various
set backspace=indent,eol,start " otherwise backspace/delete doesn't work
set wildmenu " wild*: command line completion
set wildmode=full
set autoread
set re=1
set autowrite

" Searching
set hlsearch " highlight
set showmatch " use % to jump to matching brace, begin/end of comment
set ignorecase smartcase " case-insensitive unless includes uppercase

" History
set history=10000
set undofile
set undodir=~/.vim/undo
set backupdir=~/.vim/tmp
set directory=~/.vim/tmp
if $TMUX == ''
  set clipboard+=unnamed
endif

" File Formatting
set fileformat=unix
set encoding=utf-8
set termencoding=utf-8

" Style
syntax on
color badwolf
function! s:goyo_enter()
  color pencil
endfunction
function! s:goyo_leave()
  color badwolf
endfunction
set background=dark
set t_Co=256
set number
" Restore previous cursor position
autocmd BufReadPost *
      \ if line("'\"") > 0 && line ("'\"") <= line("$") |
      \   exe "normal g`\"" |
      \ endif
" Filetype specifics
set shiftwidth=2 softtabstop=2 " default 2 spaces
autocmd FileType python,java,c,cpp set shiftwidth=4 softtabstop=4 " python requires 4 spaces
" Highlight unwanted whitespace
highlight UglySpaces ctermbg=red guibg=red
match UglySpaces /\t/
match UglySpaces /\s\+$/

" Key mappings
nnoremap ; :
let mapleader = ","
" ctrl+p for fuzzy file search
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
" ,ev = edit vimrc
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
" ,<space> = clear highlights from search
noremap <leader><space> :nohlsearch<cr>
" paste mode set, unset
nnoremap <leader>p :set paste<cr>
nnoremap <leader>P :set nopaste<cr>
" Toggle hard tab highlighting
nnoremap <leader>h :highlight UglySpaces ctermbg=red<cr>
nnoremap <leader>H :highlight clear UglySpaces<cr>
map <leader>t :NERDTreeToggle<cr>
map <leader>d :Goyo<cr>
autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()
