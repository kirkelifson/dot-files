" Plugins

autocmd!
set runtimepath+=~/.vim/bundle/vundle
call vundle#begin()
Plugin 'gmarik/vundle'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-rails'
Plugin 'vim-ruby/vim-ruby'
Plugin 'tpope/vim-surround'
Plugin 'ervandew/supertab'
Plugin 'kien/ctrlp.vim'
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
set history=10000
set nobackup
set noswapfile
set undofile
set undodir=~/.vim/undo

" Style

syntax on
color grb256
set background=dark
set t_Co=256
set smarttab
set number
set relativenumber
" make hard tabs distinct
highlight UglySpaces ctermbg=red
match UglySpaces /\t/
match UglySpaces /\s\+$/

augroup vimrcExec
    " Restore cursor to previous position on file open
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line ("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif
    " Filetype specifics
    autocmd FileType ruby,javascript,html,sass,yaml set shiftwidth=2 softtabstop=2
    autocmd BufRead *.mkd  set ai formatoptions=tcroqn2 comments=n:>
augroup END

" Key mappings

let mapleader = ","
" ,ev = edit vimrc
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
" ,<space> = clear highlights from search
noremap <leader><space> :nohlsearch<cr>
nnoremap ; :
" escape faster
imap jj <esc>
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

let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

let &titlestring = expand('%:t')
if &term == "screen"
    set title
    " TODO: learn how to retrieve current tmux window title to restore state
    autocmd BufEnter * call system("tmux rename-window " . expand('%:t'))
    autocmd VimLeave * call system("tmux rename-window zsh")
endif
