"=================================
"|          Kirk Elifson         |
"|             UCF '16           |
"|       kirk@parodybit.net      |
"=================================

set nocompatible
set history=100

" Read a file when it is changed from the outside
set autoread

" raise dialogue to save file if cmd fails
set confirm

" prevent vulnerabilities
set nomodeline

" restore cursor to last saved position on reload
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

" improved buffer functionality
set hidden

" satan uses hard tabs
set expandtab
set shiftwidth=4
set softtabstop=4
set fileformats=unix
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

" substitute global per line as default
set gdefault

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Style

set encoding=utf-8

" improves redrawing
set ttyfast

set number
set cursorline

" word wrap
set wrap
set linebreak

syntax on

set t_Co=256
colorscheme molokai
set background=dark

set laststatus=2
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ cwd:\ %r%{CurDir()}%h\ \ \ line:\ %l/%L:%c
function! CurDir()
    let curdir = substitute(getcwd(), '/home/xtc', "~", "g")
    let curdir = substitute(getcwd(), '/home/kirk', "~", "g")
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
" ,w -> new vertical split and use it
nnoremap <leader>w <C-w>v<C-w>l
" ,s -> new horizontal split and use it
nnoremap <leader>s <C-w>s<C-w>j

" improve movement with j and k
nnoremap j gj
nnoremap k gk

" redraw screen with C-l
nnoremap <C-L> :nohl<CR><C-L>

" set Y = yank until EOL
map Y y$

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle

" turn off (required!)
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle (required!)
Bundle 'gmarik/vundle'

" Vundles
Bundle 'withgod/vim-sourcepawn'
Bundle 'pangloss/vim-javascript'
Bundle 'vim-scripts/surround.vim'
Bundle 'christoomey/vim-tmux-navigator'
Bundle 'dag/vim2hs'

" turn filetype back on
filetype plugin indent on
