"=========================================
"|                                       |
"|              Kirk Elifson             |
"|                 UCF '16               |
"|          http://parodybit.net         |
"|         kelifson@parodybit.net        |
"|                                       |
"=========================================

" disclaimer: i'm an idiot do not listen to me

" originally completed: oct 2, 2012
" last updated: oct 3, 2012

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible
set autochdir
set shell=/bin/zsh
set history=2000

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

" Return to last edit position when opening files
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" Remember info about open buffers on close
set viminfo^=%

" Regular tab widths are ignorant
set tabstop=2
set shiftwidth=2
set autoindent
set expandtab
set smarttab
set backspace=indent,eol,start

filetype plugin on
filetype indent on

" Tab file completion extras
set wildmenu
set wildmode=list:longest,full

set ffs=unix,dos,mac

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search paramaters

" use grep
set grepprg=grep\ -nH\ $*

" Case insensitive
set ignorecase
set smartcase

" Incremental search
set incsearch

" linux clipboard register
let g:clipbrdDefaultReg = '+'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Style + Colors
set t_Co=256
set background=dark
colorscheme molokai

set encoding=utf8
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
        return 'PASTE MODE '
    else
        return ''
    endif
endfunction

" Show current command in use
set showcmd
set cmdheight=2

" highlight last search param
set hlsearch

" highlight matching parenthesis
highlight MatchParen ctermbg=4
set mat=2

set nowrap
set linebreak
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Scrolling

set scrolloff=8
set sidescrolloff=15
set sidescroll=1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Disable all bells

set noerrorbells
set novisualbell
set t_vb=
set tm=500
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Backups + temporary files

set nobackup
set writebackup

set backupdir=~/.tmp/backup
set directory=~/.tmp
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Key mapping

" Map 'jj' to escape on insert mode
inoremap jj <Esc>
nnoremap JJJJ <Nop>

" I will be removing the following after I grow some balls
" babby's first vimrc needs his training wheels

function! DelEmptyLineAbove()
  if line(".") == 1
    return
  endif
  let l:line = getline(line(".") - 1)
  if l:line =~ '^\s*$'
    let l:colsave = col(".")
    .-1d
    silent normal! <C-y>
    call cursor(line("."), l:colsave)
  endif
endfunction

function! AddEmptyLineAbove()
  let l:scrolloffsave = &scrolloff
" Avoid jerky scrolling with ^E at top of window
  set scrolloff=0
  call append(line(".") - 1, "")
  if winline() != winheight(0)
    silent normal! <C-e>
  endif
  let &scrolloff = l:scrolloffsave
endfunction

function! DelEmptyLineBelow()
  if line(".") == line("$")
    return
  endif
  let l:line = getline(line(".") + 1)
  if l:line =~ '^\s*$'
    let l:colsave = col(".")
    .+1d
    ''
    call cursor(line("."), l:colsave)
  endif
endfunction

function! AddEmptyLineBelow()
  call append(line("."), "")
endfunction

" Arrow key remapping: Up/Dn = move line up/dn; Left/Right = indent/unindent
function! SetArrowKeysAsTextShifters()
" normal mode
  nmap <silent> <Left> <<
  nmap <silent> <Right> >>
  nnoremap <silent> <Up> <Esc>:call DelEmptyLineAbove()<CR>
  nnoremap <silent> <Down> <Esc>:call AddEmptyLineAbove()<CR>
  nnoremap <silent> <C-Up> <Esc>:call DelEmptyLineBelow()<CR>
  nnoremap <silent> <C-Down> <Esc>:call AddEmptyLineBelow()<CR>
  nnoremap <silent> <C-S-Right> <Esc>:RightAlign<CR>

" visual mode
  vmap <silent> <Left> <
  vmap <silent> <Right> >
  vnoremap <silent> <Up> <Esc>:call DelEmptyLineAbove()<CR>gv
  vnoremap <silent> <Down> <Esc>:call AddEmptyLineAbove()<CR>gv
  vnoremap <silent> <C-Up> <Esc>:call DelEmptyLineBelow()<CR>gv
  vnoremap <silent> <C-Down> <Esc>:call AddEmptyLineBelow()<CR>gv
  vnoremap <silent> <C-S-Right> <Esc>:RightAlign<CR>gv

" insert mode
  imap <silent> <Left> <C-D>
  imap <silent> <Right> <C-T>
  inoremap <silent> <Up> <Esc>:call DelEmptyLineAbove()<CR>a
  inoremap <silent> <Down> <Esc>:call AddEmptyLineAbove()<CR>a
  inoremap <silent> <C-Up> <Esc>:call DelEmptyLineBelow()<CR>a
  inoremap <silent> <C-Down> <Esc>:call AddEmptyLineBelow()<CR>a
  inoremap <silent> <C-S-Right> <Esc>:RightAlign<CR>a

" disable modified versions we are not using
  nnoremap <S-Up> <NOP>
  nnoremap <S-Down> <NOP>
  nnoremap <S-Left> <NOP>
  nnoremap <S-Right> <NOP>
  vnoremap <S-Up> <NOP>
  vnoremap <S-Down> <NOP>
  vnoremap <S-Left> <NOP>
  vnoremap <S-Right> <NOP>
  inoremap <S-Up> <NOP>
  inoremap <S-Down> <NOP>
  inoremap <S-Left> <NOP>
  inoremap <S-Right> <NOP>
endfunction

call SetArrowKeysAsTextShifters()
