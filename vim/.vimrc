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
set laststatus=2
set cmdheight=2

syntax on
au BufNewFile,BufRead *.sp set filetype=c

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

""""""""""""""""""""""""""""""""""""""""""""""""""
" Backups

set backup
set backupdir=~/.vim/backup

set undodir=~/.vim/undo
set undofile

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
