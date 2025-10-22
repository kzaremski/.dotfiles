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
" Plug 'tribela/vim-transparent'  " Replaced with manual config below

" Fuzzy finding
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Code quality
Plug 'dense-analysis/ale'

" LSP support (Language Server Protocol) - DISABLED
" Plug 'prabirshrestha/vim-lsp'
" Plug 'mattn/vim-lsp-settings'  " Auto-install language servers
" Plug 'prabirshrestha/asyncomplete.vim'  " Async completion
" Plug 'prabirshrestha/asyncomplete-lsp.vim'  " LSP completion source

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
" Plug 'preservim/vim-markdown', { 'for': 'markdown' }
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
call plug#end()

" #####################
" ## COLOR SCHEME    ##
" #####################
colorscheme monokai

" Transparent background (manual config)
" Apply after colorscheme loads to prevent it from being overwritten
function! ApplyTransparency()
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NonText guibg=NONE ctermbg=NONE
  highlight LineNr guibg=NONE ctermbg=NONE
  highlight SignColumn guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
  highlight CursorLine guibg=NONE ctermbg=NONE
  highlight CursorLineNr guibg=NONE ctermbg=NONE
  highlight VertSplit guibg=NONE ctermbg=NONE
  highlight StatusLine guibg=NONE ctermbg=NONE
  highlight StatusLineNC guibg=NONE ctermbg=NONE
  highlight Pmenu guibg=NONE ctermbg=NONE
  highlight PmenuSel guibg=NONE ctermbg=NONE
endfunction

" Apply transparency on startup and when colorscheme changes
autocmd VimEnter,ColorScheme * call ApplyTransparency()

" #####################
" ## BASIC SETTINGS  ##
" #####################
" Enable syntax highlighting and filetype detection
syntax enable
filetype plugin indent on

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

" Integrate with system clipboard
set clipboard=unnamed,unnamedplus

" Auto-reload files when changed outside Vim (if unmodified)
set autoread
augroup autoread
  autocmd!
  " Trigger check when cursor stops moving
  autocmd CursorHold,CursorHoldI * checktime
  " Trigger check when switching buffers
  autocmd FocusGained,BufEnter * checktime
augroup END

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
" ALE: Disable completion and LSP features (we're not using LSP/asyncomplete)
let g:ale_completion_enabled = 0
let g:ale_disable_lsp = 1
let g:ale_set_balloons = 0

" vim-markdown: disable folding (I find it confusing)
let g:vim_markdown_folding_disabled = 1

" vim-lsp: Enable diagnostics and hover - DISABLED
" let g:lsp_diagnostics_enabled = 1
" let g:lsp_diagnostics_echo_cursor = 1  " Show error under cursor
" let g:lsp_document_highlight_enabled = 0  " Disable document highlighting (can be slow)
" let g:lsp_signature_help_enabled = 1  " Show function signatures

" vim-lsp: Key bindings (only active when LSP is running) - DISABLED
" function! s:on_lsp_buffer_enabled() abort
"   setlocal omnifunc=lsp#complete
"   setlocal signcolumn=yes
"
"   " Go to definition
"   nmap <buffer> gd <plug>(lsp-definition)
"   " Find references
"   nmap <buffer> gr <plug>(lsp-references)
"   " Rename symbol
"   nmap <buffer> <leader>rn <plug>(lsp-rename)
"   " Hover documentation
"   nmap <buffer> K <plug>(lsp-hover)
"   " Code actions
"   nmap <buffer> <leader>ca <plug>(lsp-code-action)
"   " Next/previous diagnostic
"   nmap <buffer> [g <plug>(lsp-previous-diagnostic)
"   nmap <buffer> ]g <plug>(lsp-next-diagnostic)
"   " Format document
"   nmap <buffer> <leader>f <plug>(lsp-document-format)
" endfunction
"
" augroup lsp_install
"   au!
"   autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
" augroup END

" asyncomplete: Tab completion - DISABLED
" inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"

" asyncomplete: Auto-popup settings for more IDE-like behavior - DISABLED
" let g:asyncomplete_auto_popup = 1  " Auto-show completion popup
" let g:asyncomplete_auto_completeopt = 0  " Don't override completeopt
" let g:asyncomplete_popup_delay = 200  " Delay before showing popup (ms)
" let g:asyncomplete_min_chars = 1  " Minimum characters to trigger

" Better completion menu appearance and behavior - DISABLED
" set completeopt=menuone,noinsert,noselect,preview  " Show menu, don't auto-insert, show preview
" set pumheight=10  " Limit popup menu height to 10 items
" set previewheight=5  " Preview window height for documentation

" Close preview window automatically when leaving insert mode - DISABLED
" autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif
" autocmd InsertLeave * if pumvisible() == 0 | pclose | endif

" vim-lsp: Show more information in completion items - DISABLED
" let g:lsp_completion_documentation_enabled = 1  " Show documentation in preview
" let g:lsp_completion_documentation_delay = 200  " Delay before showing docs

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
    \ '',
    \ '━━━ LSP (LANGUAGE SERVER) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  gd             - Go to definition',
    \ '  gr             - Find references',
    \ '  K              - Hover documentation',
    \ '  <leader>rn     - Rename symbol',
    \ '  <leader>ca     - Code actions',
    \ '  <leader>f      - Format document',
    \ '  [g  ]g         - Jump between diagnostics',
    \ '  :LspInstallServer  - Install language server for current file',
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
    \ '━━━ TEXT OBJECTS & MOTIONS (VIM MASTERY) ━━━━━━━━━━━━━━━━',
    \ '  ciw        - Change inner word',
    \ '  ca"        - Change around quotes (includes quotes)',
    \ '  dap        - Delete around paragraph',
    \ '  vi(        - Visual select inside parentheses',
    \ '  ya{        - Yank around braces',
    \ '  dit        - Delete inside HTML tag',
    \ '  d3w        - Delete 3 words',
    \ '  c2i(       - Change 2 levels of parentheses',
    \ '  {  }       - Jump by paragraph',
    \ '  %          - Jump to matching bracket/paren/tag',
    \ '',
    \ '━━━ MACROS (AUTOMATE REPETITIVE TASKS) ━━━━━━━━━━━━━━━━━━',
    \ '  qa         - Start recording macro to register "a"',
    \ '  q          - Stop recording',
    \ '  @a         - Replay macro from register "a"',
    \ '  @@         - Repeat last macro',
    \ '  10@a       - Replay macro 10 times',
    \ '',
    \ '━━━ REGISTERS & CLIPBOARD ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  "ayy       - Yank line to register "a"',
    \ '  "ap        - Paste from register "a"',
    \ '  "0p        - Paste last yank (not last delete)',
    \ '  :reg       - Show all registers',
    \ '  "+y        - Yank to system clipboard',
    \ '  "+p        - Paste from system clipboard',
    \ '',
    \ '━━━ MARKS & NAVIGATION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  ma         - Set mark "a" at cursor',
    \ '  `a         - Jump to exact position of mark "a"',
    \ '  ''a         - Jump to line of mark "a"',
    \ '  ''          - Jump back to previous position',
    \ '  `.         - Jump to last change',
    \ '  Ctrl+o     - Jump to older position',
    \ '  Ctrl+i     - Jump to newer position',
    \ '',
    \ '━━━ ADVANCED SEARCH & REPLACE ━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  :%s/old/new/gc        - Replace with confirmation',
    \ '  :''<,''>s/old/new/g     - Replace in visual selection',
    \ '  :g/pattern/d          - Delete all lines matching pattern',
    \ '  :v/pattern/d          - Delete lines NOT matching',
    \ '  :g/TODO/t$            - Copy all TODO lines to end',
    \ '  n  N                  - Next/previous search result',
    \ '  *  #                  - Search word under cursor',
    \ '',
    \ '━━━ QUICKFIX & LOCATION LISTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  :copen     - Open quickfix window (errors, search)',
    \ '  :cnext     - Next quickfix item',
    \ '  :cprev     - Previous quickfix item',
    \ '  :cclose    - Close quickfix window',
    \ '  :Rg <pat>  - Search with ripgrep → quickfix list',
    \ '',
    \ '━━━ SPLITS & WINDOWS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    \ '  :sp        - Split horizontally',
    \ '  :vsp       - Split vertically',
    \ '  Ctrl+w h/j/k/l  - Navigate splits',
    \ '  Ctrl+w =   - Equalize split sizes',
    \ '  Ctrl+w _   - Maximize height',
    \ '  Ctrl+w |   - Maximize width',
    \ '  Ctrl+w q   - Close current split',
    \ '',
    \ '━━━ THE DOT COMMAND (MOST POWERFUL) ━━━━━━━━━━━━━━━━━━━━━',
    \ '  .          - Repeat last change',
    \ '  cw         - Change word, then use . on next word',
    \ '  daw        - Delete a word, then use . to delete more',
    \ '  >          - Indent, then use . to indent more lines',
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
