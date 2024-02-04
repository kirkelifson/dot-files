filetype plugin indent on
syntax on

" Whitespace
set expandtab " converts tabs to spaces
set autoindent

" Various
set backspace=indent,eol,start " otherwise backspace/delete doesn't work
set wildmenu " wild*: command line completion
set wildmode=full
set autoread
set re=1
set autowrite
set laststatus=2 " lightline requirement
set noshowmode
set rtp+=/usr/local/opt/fzf
set mouse=a
set mmp=5000

" Searching
set hlsearch " highlight
set showmatch " use % to jump to matching brace, begin/end of comment
set ignorecase smartcase " case-insensitive unless includes uppercase

" History
set history=10000
set undofile
set undodir=~/.vim/undo
set backupdir=~/.vim/tmp
set directory=~/.vim/tmp
if $TMUX == ''
  set clipboard+=unnamed
endif

" File Formatting
set fileformat=unix
set encoding=utf-8
set termencoding=utf-8

" Style
syntax on
silent! color sierra
set background=dark
set t_Co=256
set number
" Restore previous cursor position
autocmd BufReadPost *
      \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
      \ |   exe "normal! g`\""
      \ | endif
" Filetype specifics
set shiftwidth=2 softtabstop=2 " default 2 spaces
autocmd FileType python,java,c,cpp set shiftwidth=4 softtabstop=4 " python requires 4 spaces
autocmd BufNewFile,BufReadPost *.md set filetype=markdown
autocmd BufNewFile,BufReadPost *.plan set filetype=markdown
" Highlight unwanted whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()
" Highlight todo
highlight Todo ctermbg=red guibg=red
match TODO /\s\+$/
autocmd BufWinEnter * match TODO /TODO/
" Key mappings
nnoremap ; :
let mapleader = ","
" ctrl+p for fuzzy file search
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
" ,ev = edit vimrc
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
" ,<space> = clear highlights from search
noremap <leader><space> :nohlsearch<cr>
" paste mode set, unset
nnoremap <leader>p :set paste<cr>
nnoremap <leader>P :set nopaste<cr>
map <leader>t :NERDTreeToggle<cr>

set splitbelow
set splitright

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
