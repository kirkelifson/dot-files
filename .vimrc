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

colorscheme molokai
set background=dark
set t_Co=256
syntax enable
" improves redrawing
set ttyfast
set number
set laststatus=2
" highlight hard tabs
highlight UglySpaces ctermbg=red
match UglySpaces /\t/

""""""""""""""""""""""""""""""""""""""""""""""""""
" Backups

set backup
set backupdir=~/.vim/backup
set undofile
set undodir=~/.vim/undo

""""""""""""""""""""""""""""""""""""""""""""""""""
" Key mapping

let mapleader = ","
" ,ev to edit vimrc
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
nnoremap / /\v
vnoremap / /\v
" clear search highlighting
noremap <leader><space> :noh<cr>
" easier command entering
nnoremap ; :
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
    " restore cursor to previous position on file open
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif

    " extension based properties
    autocmd FileType ruby,javascript,html,sass set sw=2 sts=2
    autocmd FileType text setlocal textwidth=80 formatoptions+=t
    autocmd FileType mkd setlocal syn=off
    autocmd BufRead *.mkd set formatoptions=tcroqn2 comments=n:&gt;
    autocmd BufRead *.markdown set formatoptions=tcroqn2 comments=n:&gt;
    autocmd BufRead,BufNewFile *.sass set filetype sass
    autocmd BufRead,BufNewFile *.sp set filetype c
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle

filetype off

set rtp+=~/.vim/bundle/vundle
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
" Vundles

" left-margin diffing
Plugin 'airblade/vim-gitgutter'
" syntax and indent profiles for .git*
Plugin 'tpope/vim-git'
" fancy statusbar theme~
Plugin 'bling/vim-airline'
" transform contents of quotes, parens
Plugin 'tpope/vim-surround'
" file-finding stuff
Plugin 'kien/ctrlp.vim'
call vundle#end()

filetype plugin indent on
