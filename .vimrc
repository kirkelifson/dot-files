" General

set expandtab
set shiftwidth=4
set softtabstop=4
set autoindent
set backspace=indent,eol,start
" soft-wrap
set fo-=t
set wildmenu
set wildmode=full
set ignorecase smartcase
set showmatch
set nocompatible
set fileformat=unix
set encoding=utf-8
set term=xterm-256color
set termencoding=utf-8
" backups
set undofile
set undodir=$HOME/.vim/undo
set undolevels=1000
set undoreload=10000
set history=10000

augroup restore
    autocmd!
    " restore cursor to previous position on file open
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif
augroup END

augroup filetypes
    autocmd!
    autocmd FileType ruby,javascript,html,sass set sw=2 sts=2
    autocmd FileType text setlocal textwidth=80 formatoptions-=t
    autocmd FileType mkd setlocal syn=off
    autocmd BufRead *.mkd set formatoptions=tcroqn2 comments=n:&gt;
augroup END

augroup reload_vimrc
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END

" Style

syntax on
color grb256
set t_Co=256
set cursorline
set showtabline=2
set cmdheight=1
set winwidth=79
set laststatus=1
set number
set relativenumber
set fillchars+=stl:\ ,stlnc:\
" make hard tabs distinct
highlight UglySpaces ctermbg=red
match UglySpaces /\t/

" Keys

let mapleader = ","
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
noremap <leader><space> :noh<cr>
nnoremap ; :
map Y y$

" Vundle

filetype off
set rtp+=~/.vim/bundle/vundle
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-surround'
call vundle#end()
filetype plugin indent on
