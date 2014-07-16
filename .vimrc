""""""""""""""""""""""""""""""""""""""""""""""""""
" General

set nocompatible
set history=10000
" improved buffer functionality
set hidden
" satan uses hard tabs
" extra tab options in autocmds (filetypes)
set expandtab
set shiftwidth=4
set softtabstop=4
set autoindent
set fileformat=unix
" backspace over everything in insert mode
set backspace=indent,eol,start
set wildmenu
set wildmode=full
" Case insensitive
set ignorecase smartcase
" Incremental search
set incsearch
set showmatch
set hlsearch
set encoding=utf-8

""""""""""""""""""""""""""""""""""""""""""""""""""
" Style

" colors
colorscheme molokai
set background=dark
set t_Co=256
syntax enable

" improves redrawing
set ttyfast
set number
set laststatus=2

" highlight hard tabs
highlight UglySpaces ctermbg=red guibg=red
match UglySpaces /\s\+$\| \+\ze\t/

""""""""""""""""""""""""""""""""""""""""""""""""""
" Backups

set backup
set backupdir=~/.vim/backup

set undofile
set undodir=~/.vim/undo

""""""""""""""""""""""""""""""""""""""""""""""""""
" Key mapping

let mapleader = ","

" ,ev -> edit vimrc
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>

nnoremap / /\v
vnoremap / /\v

" clear search highlighting
noremap <leader><space> :noh<cr>

" easier command entering
nnoremap ; :
inoremap jj <ESC>

" improve movement with j and k
nnoremap j gj
nnoremap k gk

" redraw screen with C-l
nnoremap <C-L> :nohl<CR><C-L>

" set Y = yank until EOL
map Y y$

""""""""""""""""""""""""""""""""""""""""""""""""""
" autocmds

augroup exec
    autocmd!
    autocmd FileType text setlocal textwidth=78
    autocmd BufReadPost *
      \ if line("'\"") > 0 && line ("'\"") <= line("$") |
      \   exe "normal g`\"" |
      \ endif

    autocmd FileType ruby,javascript,html,sass set ai sw=2 sts=2 et
    autocmd FileType python set sw=4 sts=4 et

    autocmd! BufRead,BufNewFile *.sass set filetype sass
    autocmd! BufRead,BufNewFile *.sp set filetype c

    " markdown
    autocmd BufRead *.mkd set ai formatoptions=tcroqn2 comments=n:&gt;
    autocmd BufRead *.markdown set ai formatoptions=tcroqn2 comments=n:&gt;
    autocmd! FileType mkd setlocal syn=off
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle

filetype off

set rtp+=~/.vim/bundle/vundle
call vundle#begin()

Plugin 'gmarik/Vundle.vim'

" Vundles
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-git'
Plugin 'bling/vim-airline'
Plugin 'vim-scripts/surround.vim'

call vundle#end()
filetype plugin indent on
