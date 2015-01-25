" Plugins

set runtimepath+=~/.vim/bundle/vundle
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-surround'
Plugin 'ervandew/supertab'
call vundle#end()
filetype plugin indent on

" General

set expandtab
set shiftwidth=4
set softtabstop=4
set autoindent
set backspace=indent,eol,start
set wildmenu
set wildmode=full
set ignorecase smartcase
set hlsearch
set showmatch
set nocompatible
set fileformat=unix
set encoding=utf-8
set termencoding=utf-8
set term=xterm-256color
set history=10000
set undofile
set undodir=~/.vim/undo
set backupdir=~/.vim/backup
set autochdir

" Style

syntax on
color grb256
set background=dark
set t_Co=256
set showtabline=2
set number
set relativenumber
" make hard tabs distinct
highlight UglySpaces ctermbg=red
match UglySpaces /\t/

augroup vimrcExec
    autocmd!
    " Restore cursor to previous position on file open
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif
    " Filetype specifics
    autocmd FileType ruby,javascript,html,sass,yaml set shiftwidth=2 softtabstop=2
    autocmd FileType python set shiftwidth=4 softtabstop=4
    autocmd FileType mkd,md set syntax=off formatoptions=tcroqn2 comments=n:&gt;
augroup END

" Key mappings

let mapleader = ","
" ,ev = edit vimrc
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
" ,<space> = clear highlights from search
noremap <leader><space> :nohlsearch<cr>
nnoremap ; :
" Move around splits with <c-hjkl>
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l
nnoremap <leader>p :set paste<cr>
nnoremap <leader>P :set nopaste<cr>
" Toggle hard tab highlighting
nnoremap <leader>h :highlight UglySpaces ctermbg=red<cr>
nnoremap <leader>H :highlight clear UglySpaces<cr>
