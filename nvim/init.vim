"nice to have default configs
set nocompatible
filetype plugin on
syntax enable
set path+=** 	"	" search recursively for files with :find
set autoread		" automatically read file when changed outside of vim

set hidden		" dont ask to save buffers before switching
set number		" Show line numbers
set showbreak=+++	" Wrap-broken line prefix
set textwidth=100	" Line wrap (number of cols)
let &colorcolumn="100,".join(range(120,999),",")
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
set cursorline 		" Highlight current line
set mouse=a		" Enable mouse in all modes
set ruler		" Show the cursor position
set termguicolors	" Color Schema
set wildmenu		" Enhance command-line completion
" show all characters that aren't white-space. So spaces are the only thing that doesn't show up.
set listchars=eol:$,tab:→\ ,trail:~,extends:>,precedes:<,nbsp:☠
set list
set updatetime=100	" To be able to see gitgutter signs more quickly
set completeopt=menuone,noselect " completion menu like a IDE 
set spelllang=en_us,pt_br
set noswapfile	"	" no swap files, I like to live dangerously
" ignore files
set wildignore+=*.pyc,*.o,*.obj,*.svn,*.swp,*.class,*.hg,*.DS_Store,*.min.*,node_files

" this will install vim-plug if not installed
if empty(glob('~/.config/nvim/autoload/plug.vim'))
    silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.vim/bundle')
        Plug 'neovim/nvim-lspconfig'
        Plug 'jacoborus/tender.vim'
        Plug 'itchyny/vim-gitbranch'
        Plug 'itchyny/lightline.vim'
        Plug 'nvim-lua/popup.nvim'
        Plug 'nvim-lua/plenary.nvim'
        Plug 'nvim-telescope/telescope.nvim'
        Plug 'airblade/vim-gitgutter'
        Plug 'tpope/vim-fugitive'
        Plug 'hrsh7th/nvim-compe'
        Plug 'tzachar/compe-tabnine', { 'do': './install.sh' }
        Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm i'  }
        Plug 'hrsh7th/vim-vsnip'
        Plug 'hrsh7th/vim-vsnip-integ'
        Plug '/usr/local/opt/fzf'
        Plug 'junegunn/fzf.vim'
        Plug 'pangloss/vim-javascript'
        Plug 'folke/lsp-colors.nvim'
        Plug 'kyazdani42/nvim-web-devicons'
        Plug 'folke/trouble.nvim'
        Plug 'tpope/vim-vinegar'
call plug#end()


colorscheme tender
" Status Bar
let g:lightline = {
      \ 'colorscheme': 'tender',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'gitbranch#name'
      \ },
      \ }

" fzf search plugin
set rtp+=/usr/local/opt/fzf

let g:ackprg = 'ag --vimgrep'
" default plugins
runtime macros/matchit.vim
hi CursorLine cterm=NONE ctermbg=darkred ctermfg=white guibg=darkred guifg=white
" shortcuts

let mapleader=" "

" Find files using Telescope command line sugar.
nnoremap <leader>ff <cmd>Telescope live_grep<cr>
nnoremap <leader>fg <cmd>Telescope git_files<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fs <cmd>Telescope grep_string<cr>

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

" Makes Y behaves like others commands
nnoremap Y y$
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap J mzJ`z

" creates undo history as you go
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ( (<c-g>u
inoremap { {<c-g>u
inoremap " "<c-g>u

" files navigation

" change %:h (which expands to file directory) to %%
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'

" Closes all buffers but this current
nnoremap <leader>ca :w <bar> %bd <bar> e# <bar> bd# <CR>

" lsp servers configuration
lua require("lspinit")

" autocomplete based in lsp
lua require("compecfg")

lua require("lsp-colors").setup({
      \  Error = "#db4b4b",
      \ Warning = "#e0af68",
      \ Information = "#0db9d7",
      \ Hint = "#10B981"
      \})

lua require("trouble").setup { }
" its mappings

inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })

nnoremap <leader>n -<CR>
