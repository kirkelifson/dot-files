"=========================================
"|                                       |
"|              Kirk Elifson             |
"|                 UCF '16               |
"|          http://parodybit.net         |
"|         kelifson@parodybit.net        |
"|                                       |
"=========================================

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible
set history=50

set titlestring=vim\ %{expand(\"%t\")}

" Read a file when it is changed from the outside
set autoread

" Remove any trailing whitespace in the file
autocmd BufRead,BufWrite * if ! &bin | silent! %s/\s\+$//ge | endif

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
    " Need to postpone using "zv" until after reading the modelines.
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
set autoindent
set shiftwidth=4
set softtabstop=4
set expandtab
set fileformats=unix,dos

filetype off

" Tab file completion extras
set wildmenu
set wildmode=full

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search paramaters

" use grep
set grepprg=grep\ -nH\ $*

" Case insensitive
set ignorecase
set smartcase

" Incremental search
set incsearch

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Style

set guifont=DejaVu\ Sans\ Mono\ 9

set showmatch
set cursorline
set relativenumber

if &t_Co > 2 || has("gui_running")
    syntax on
    set background=dark
    set hlsearch
endif

set t_Co=256 " force 256 colors
colorscheme molokai

if has("autocmd")
    " Filetypes and indenting settings
    filetype plugin indent on

    " For all text files set 'textwidth' to 78 characters.
    autocmd FileType text setlocal textwidth=78

    " When editing a file, always jump to the last known cursor position.
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \ exe "normal g`\"" |
        \ endif
endif " has("autocmd")

" UTF-8 master-race
set encoding=utf-8
set number
set ruler

set laststatus=2
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ cwd:\ %r%{CurDir()}%h\ \ \ line:\ %l/%L:%c
function! CurDir()
    let curdir = substitute(getcwd(), '/home/xtc', "~", "g")
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
set cmdheight=2

" don't wrap text
set nowrap
set linebreak

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Scrolling

set scrolloff=2
set sidescrolloff=15
set sidescroll=1
set foldmethod=indent
set foldlevel=99

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Disable all bells

set noerrorbells
set novisualbell
set t_vb=
set tm=500

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Backups + temporary files

set nobackup

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Key mapping

" Map 'jj' to escape on insert mode
inoremap jj <Esc>
nnoremap JJJJ <Nop>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Allow for local overrides
if filereadable(expand("~/.vimrc.local"))
    source ~/.vimrc.local
endif
