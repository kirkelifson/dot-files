"=========================================
"|                                       |
"|              Kirk Elifson             |
"|                 UCF '16               |
"|           kirk@parodybit.net          |
"|                                       |
"=========================================

set nocompatible
set history=50

" Read a file when it is changed from the outside
set autoread

augroup JumpCursorOnEdit
    au!
    autocmd BufReadPost *
        \ if expand("<afile>:p:h") !=? $TEMP |
            \ if line("'\"") > 1 && line("'\"") <= line("$") |
                \ let JumpCursorOnEdit_foo = line("'\"") |
                \ let b:doopenfold = 1 |
                \ if (foldlevel(JumpCursorOnEdit_foo) > foldlevel(JumpCursorOnEdit_foo - 1)) |
                    \ let JumpCursorOnEdit_foo = JumpCursorOnEdit_foo - 1 |
                    \ let b:doopenfold = 2 |
                \ endif |
                \ exe JumpCursorOnEdit_foo |
            \ endif |
        \ endif
    autocmd BufWinEnter *
        \ if exists("b:doopenfold") |
            \ exe "normal zv" |
            \ if(b:doopenfold > 1) |
                \ exe "+".1 |
            \ endif |
            \ unlet b:doopenfold |
        \ endif
augroup END

" Regular tab widths are ignorant
set expandtab
set shiftwidth=4
set softtabstop=4
set fileformats=unix,dos
set cindent
set autoindent

" backspace over everything in insert mode
set backspace=indent,eol,start

" Tab file completion extras
set wildmenu
set wildmode=full

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Case insensitive
set ignorecase
set smartcase

" Incremental search
set incsearch
set showmatch
set hlsearch

set gdefault

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Style

set encoding=utf-8

set number
set cursorline
set wrap
set linebreak

syntax on
set background=dark

set t_Co=256
colorscheme molokai

set laststatus=2
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ cwd:\ %r%{CurDir()}%h\ \ \ line:\ %l/%L:%c
function! CurDir()
    let curdir = substitute(getcwd(), '/home/xtc', "~", "g")
    let curdir = substitute(getcwd(), '/home/kelifson', "~", "g")
    return curdir
endfunction
function! HasPaste()
    if &paste
        return 'paste mode '
    else
        return ''
    endif
endfunction

" Show current command in use
set showcmd
set cmdheight=1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Scrolling

set sidescroll=1
set scrolloff=2
set sidescrolloff=15
set foldmethod=indent
set foldlevel=99

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Disable all bells

set noerrorbells
set novisualbell

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Backups + temporary files

set nobackup
set writebackup

set undodir=~/.vim/undo
set undofile

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

call pathogen#runtime_append_all_bundles()
filetype off
syntax on
filetype plugin indent on

set modelines=0

set ttyfast

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Key mapping

let mapleader = ","
nnoremap / /\v
vnoremap / /\v
noremap <leader><space> :noh<cr>
nnoremap <tab> %
vnoremap <tab> %

nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

nnoremap ; :
inoremap jj <ESC>

nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
nnoremap <leader>w <C-w>v<C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
