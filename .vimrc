" Konstantin Zaremski's VIM config
" Last updated: October 11, 2025

" ######################
" ## INSTALL VIM PLUG ##
" ######################
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" ######################
" ## VIM PLUG PLUGINS ##
" ######################
call plug#begin()
" Appearance
Plug 'vim-airline/vim-airline'
Plug 'sickill/vim-monokai'
Plug 'tribela/vim-transparent'

" Fuzzy finding
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Code quality
Plug 'dense-analysis/ale'

" Tim Pope essentials
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-vinegar'

" Markdown / blog post writing
Plug 'junegunn/limelight.vim'
Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
call plug#end()

" #####################
" ## COLOR SCHEME    ##
" #####################
colorscheme monokai

" #####################
" ## BASIC SETTINGS  ##
" #####################
" Line numbering - hybrid (relative in active window, absolute in insert mode)
set number
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

" Tabs are 4-wide spaces
set expandtab
set tabstop=4
set shiftwidth=4

" Enable mouse support (works in tmux, overrides tmux scrolling)
set mouse=a
if has("mouse_sgr")
  set ttymouse=sgr
else
  set ttymouse=xterm2
endif

" #####################
" ## KEY MAPPINGS    ##
" #####################
" FZF fuzzy finding
nnoremap <C-p> :Files<CR>
nnoremap <C-b> :Buffers<CR>
nnoremap <C-f> :Rg<CR>

" Toggle spell check with F5
map <F5> :setlocal spell! spelllang=en_us<CR>

" Show custom manual with F1
nnoremap <F1> :Manual<CR>

" File browser - press '-' to open directory of current file (vim-vinegar)

" #####################
" ## PLUGIN CONFIG   ##
" #####################
" vim-markdown: disable folding (I find it confusing)
let g:vim_markdown_folding_disabled = 1

" #######################
" ## CUSTOM FUNCTIONS  ##
" #######################
" Custom Vim manual/cheatsheet
command! Manual call ShowManual()
function! ShowManual()
  " Create a new scratch buffer
  new
  setlocal buftype=nofile bufhidden=wipe noswapfile
  setlocal filetype=help

  " Insert the manual content
  call append(0, [
    \ '╔════════════════════════════════════════════════════════════╗',
    \ '║         KONSTANTIN''S VIM MANUAL & CHEATSHEET               ║',
    \ '╚════════════════════════════════════════════════════════════╝',
    \ '',
    \ '━━━ FUZZY FINDING (FZF) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  Ctrl+P     - Find files by name',
    \ '  Ctrl+B     - Switch between open buffers',
    \ '  Ctrl+F     - Search text in files (requires ripgrep)',
    \ '',
    \ '━━━ FILE NAVIGATION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  -          - Open file browser in current directory',
    \ '  Ctrl+^     - Switch to last/alternate buffer',
    \ '  :e <file>  - Edit/open a file',
    \ '  :bd        - Close current buffer',
    \ '',
    \ '━━━ EDITING & COMMENTING ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  gcc        - Toggle comment on current line',
    \ '  gc         - Toggle comment (in visual mode)',
    \ '  gcc5j      - Comment current line + next 5 lines',
    \ '',
    \ '━━━ SURROUND (QUOTES, BRACKETS, TAGS) ━━━━━━━━━━━━━━━━━━━',
    \ '  cs"''       - Change surrounding " to ''',
    \ '  cs''<q>     - Change surrounding '' to <q></q> tags',
    \ '  ds"        - Delete surrounding "',
    \ '  dst        - Delete surrounding HTML tag',
    \ '  ysiw"      - Surround inner word with "',
    \ '  yss)       - Surround entire line with ( )',
    \ '  Visual S"  - Surround visual selection with "',
    \ '',
    \ '━━━ GIT (FUGITIVE) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  :Git status       - Show git status',
    \ '  :Git add %        - Stage current file',
    \ '  :Git commit       - Commit staged changes',
    \ '  :Git push         - Push to remote',
    \ '  :Git blame        - Show git blame for current file',
    \ '  :Git diff         - Show git diff',
    \ '  :Git log          - Show git log',
    \ '',
    \ '━━━ MARKDOWN ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  :MarkdownPreview       - Open live preview in browser',
    \ '  :MarkdownPreviewStop   - Stop preview server',
    \ '  :Limelight             - Focus mode (dim paragraphs)',
    \ '  :Limelight!            - Exit focus mode',
    \ '  :Tabularize /<char>    - Align text by character',
    \ '',
    \ '━━━ CODE QUALITY (ALE) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  :ALEToggle    - Enable/disable linting',
    \ '  :ALEDetail    - Show detailed error message',
    \ '  [g  ]g        - Jump between errors/warnings',
    \ '',
    \ '━━━ HYBRID LINE NUMBERS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  Active window:   Shows relative numbers (for motions)',
    \ '  Inactive window: Shows absolute numbers',
    \ '  Insert mode:     Shows absolute numbers',
    \ '',
    \ '━━━ MOUSE SUPPORT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  Mouse is enabled! Click, drag, scroll, and select.',
    \ '  Works in tmux - overrides tmux scrolling when in vim.',
    \ '',
    \ '━━━ MISC SHORTCUTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  F1         - Show this manual',
    \ '  F5         - Toggle spell check (US English)',
    \ '  :Manual    - Show this manual (alternative)',
    \ '',
    \ '━━━ USEFUL VIM COMMANDS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  :w         - Save file',
    \ '  :q         - Quit window',
    \ '  :wq        - Save and quit',
    \ '  :q!        - Quit without saving',
    \ '  u          - Undo',
    \ '  Ctrl+r     - Redo',
    \ '  .          - Repeat last command',
    \ '  *          - Search for word under cursor',
    \ '  :%s/old/new/g  - Replace all "old" with "new"',
    \ '',
    \ '━━━ VISUAL MODE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  v          - Visual mode (character)',
    \ '  V          - Visual mode (line)',
    \ '  Ctrl+v     - Visual mode (block)',
    \ '  o          - Toggle cursor to opposite end of selection',
    \ '',
    \ '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '',
    \ 'Press q to close this window',
    \ 'Press / to search within this manual',
    \ ])

  " Move cursor to top and make read-only
  normal! gg
  setlocal nomodifiable

  " Map q to close the window
  nnoremap <buffer> q :q<CR>

  " Resize window
  resize 40
endfunction
