"nice to have default configs
set nocompatible
filetype plugin on
set hidden		" dont ask to save buffers before switching
set number		" Show line numbers
set linebreak		" Break lines at word (requires Wrap lines)
set showbreak=+++	" Wrap-broken line prefix
set textwidth=100	" Line wrap (number of cols)
set showmatch		" Highlight matching brace
set spell		" Enable spell-checking
set visualbell		" Use visual bell (no beeping)
 
set hlsearch		" Highlight all search results
set smartcase		" Enable smart-case search
set ignorecase		" Always case-insensitive
set incsearch		" Searches for strings incrementally
 
set autoindent		" Auto-indent new lines
set expandtab		" Use spaces instead of tabs
set shiftwidth=2	" Number of auto-indent spaces
set smartindent		" Enable smart-indent
set smarttab		" Enable smart-tabs
set softtabstop=2	" Number of spaces per Tab::J

" this will install vim-plug if not installed
if empty(glob('~/.config/nvim/autoload/plug.vim'))
    silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.vim/bundle')
" here you'll add all the plugins needed
        Plug 'neovim/nvim-lspconfig'
	Plug 'jacoborus/tender.vim'
	Plug 'itchyny/lightline.vim'
        Plug 'nvim-lua/popup.nvim'
        Plug 'nvim-lua/plenary.nvim'
        Plug 'nvim-telescope/telescope.nvim'
call plug#end()

" Color Schema
if (has("termguicolors"))
 set termguicolors
endif
syntax enable
colorscheme tender
" Status Bar
let g:lightline = { 'colorscheme': 'tender' }

" default plugins
runtime macros/matchit.vim

" shortcuts

let mapleader=" "

" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope git_files<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Navigating between buffers
nnoremap <silent> [b :bp<CR>
nnoremap <silent> [B :bn<CR>
nnoremap <silent> ]b :bf<CR>
nnoremap <silent> ]B :bl<CR>

" Leaders key

" window related
nnoremap <silent> <Leader>w <C-w>

" Exit from terminal mode
tnoremap <Esc> <C-\><C-n>

" files navigation

" change %:h (which expands to file directory) to %%
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'

" Set current pwd to the buffer I entered
" autocmd BufEnter * silent! lcd %:p:h

