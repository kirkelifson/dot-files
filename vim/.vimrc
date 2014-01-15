""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible
set history=1000
" Read upon file change
set autoread
set modeline
set modelines=3
" improved buffer functionality
set hidden
" satan uses hard tabs
" extra tab options in autocmds (filetypes)
set expandtab
set shiftwidth=4
set softtabstop=4
set fileformat=unix
set autoindent
" backspace over everything in insert mode
set backspace=indent,eol,start
" Tab file completion extras
set wildmenu
set wildmode=full
" Case insensitive
set ignorecase
set smartcase
" Incremental search
set incsearch
set showmatch
set hlsearch
set encoding=utf-8

set showtabline=2

""""""""""""""""""""""""""""""""""""""""""""""""""
" Style

" highlight hard tabs
highlight HardTabs ctermbg=red guibg=red
match HardTabs /\t/
" improves redrawing
set ttyfast
set number
set cursorline
" word wrap
set wrap
set linebreak
set t_Co=256
color grb256
set winwidth=79
set laststatus=2
set cmdheight=1

syntax on

set statusline=%<%f\ (%{&ft})\ %-4(%m%)%=%-19(%3l,%02c%03V%)

""""""""""""""""""""""""""""""""""""""""""""""""""
" Backups

set backup
set backupdir=~/.vim/backup

set undofile
set undodir=~/.vim/undo

""""""""""""""""""""""""""""""""""""""""""""""""""
" Key mapping

let mapleader = ","
nnoremap / /\v
vnoremap / /\v
nnoremap <tab> %
vnoremap <tab> %

" clear search highlighting
noremap <leader><space> :noh<cr>

" easier command entering
nnoremap ; :
inoremap jj <ESC>

" ,ev -> edit vimrc
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>

" improve movement with j and k
nnoremap j gj
nnoremap k gk

" redraw screen with C-l
nnoremap <C-L> :nohl<CR><C-L>

" set Y = yank until EOL
map Y y$

""""""""""""""""""""""""""""""""""""""""""""""""""
" autocmds

augroup vimrcEx
    autocmd!
    autocmd FileType text setlocal textwidth=78
    autocmd BufReadPost *
      \ if line("'\"") > 0 && line ("'\"") <= line("$") |
      \   exe "normal g`\"" |
      \ endif

    autocmd FileType ruby,javascript,html,sass set ai sw=2 sts=2 et
    autocmd FileType python set sw=4 sts=4 et

    autocmd! BufRead,BufNewFile *.sass setfiletype sass
    autocmd! BufRead,BufNewFile *.sp set filetype=c

    " markdown
    autocmd BufRead *.mkd set ai formatoptions=tcroqn2 comments=n:&gt;
    autocmd BufRead *.markdown set ai formatoptions=tcroqn2 comments=n:&gt;
    autocmd! FileType mkd setlocal syn=off
augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle

" turn off (required!)
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle (required!)
Bundle 'gmarik/vundle'

" Vundles
Bundle 'vim-scripts/surround.vim'
Bundle 'dag/vim2hs'

" turn filetype back on
filetype plugin indent on
