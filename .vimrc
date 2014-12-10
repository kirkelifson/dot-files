autocmd!

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
set hlsearch
set incsearch
set showmatch
set nocompatible
set history=10000
set fileformat=unix
set encoding=utf-8
set nobackup
set nowritebackup
set backupdir=~/.vim/backup
set term=xterm-256color
set termencoding=utf-8

augroup exec
    " restore cursor to previous position on file open
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif
    autocmd FileType ruby,javascript,html,sass set sw=2 sts=2
    autocmd FileType text setlocal textwidth=80 formatoptions-=t
    autocmd FileType mkd setlocal syn=off
    autocmd BufRead *.mkd set formatoptions=tcroqn2 comments=n:&gt;
augroup END

" Style

color grb256
syntax on
set background=dark
set cursorline
set showtabline=2
set cmdheight=1
set winwidth=79
set laststatus=2
set t_Co=256
set number
set relativenumber
set fillchars+=stl:\ ,stlnc:\
highlight UglySpaces ctermbg=red
match UglySpaces /\t/

" Keys

let mapleader = ","
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
noremap <leader><space> :noh<cr>
nnoremap ; :
map Y y$

" Vundle

" these are required before vundle for some reason
filetype off
set rtp+=~/.vim/bundle/vundle
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-git'
Bundle 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
" transform contents of quotes, parens
Plugin 'tpope/vim-surround'
" neat file management
Plugin 'kien/ctrlp.vim'

call vundle#end()
filetype plugin indent on
