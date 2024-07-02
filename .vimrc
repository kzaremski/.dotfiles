" Konstantin Zaremski's VIM config!
"     vim based, fr fr
" August 24, 2023

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
Plug 'preservim/nerdtree'

call plug#end()

" #####################
" ## NERDTREE CONFIG ##
" #####################
let g:NERDTreeWinPos = "right"
"nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
" Cloe nerdtree if it is the only buffer left open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif


" #################################
" ## USER SPECIFIC CONFIGURATION ##
" #################################
" Line Numbering
set number

" Tabs are 4-wide spaces by default
set expandtab
set tabstop=4
set shiftwidth=4


