"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible " VI compatible mode is disabled so that VIm things work

" ************** Vim Package Manager ***********
" packadd termdebug


" =================================================
" ************* Vim-Plug ************
" =================================================

" Plugins will be downloaded under the specified directory.
call plug#begin('~/.vim/plugged')

" ===>> Declare the list of plugins:

" Auto Complete
" Plug 'tmsvg/pear-tree'
Plug 'neoclide/coc.nvim', {'branch': 'release'}     " CoC Complition API for Vim!
Plug 'andys8/vscode-jest-snippets'                  " VSCode Snippets Extension from Github
Plug 'honza/vim-snippets'                           " snippet support that integrates with CoC
Plug 'jiangmiao/auto-pairs'                         " Auto pairs for Vim...

" Color Schemes
Plug 'sonph/onehalf', {'rtp': 'vim/'}
Plug 'rakr/vim-one'
Plug 'joshdick/onedark.vim'
Plug 'tomasr/molokai'
Plug 'jacoborus/tender.vim'
Plug 'ayu-theme/ayu-vim'
Plug 'nanotech/jellybeans.vim'
Plug 'morhetz/gruvbox'
Plug 'shinchu/lightline-gruvbox.vim'


" Text Manipulation
Plug 'tpope/vim-unimpaired'           " Pairs of mappings
Plug 'joom/vim-commentary'            " To comment stuff out
Plug 'terryma/vim-multiple-cursors'   " Multiple cursors like sublime
Plug 'tpope/vim-surround'			  " Surround with parentheses & co


" Interacts with coc!
Plug 'tpope/vim-repeat'               " Adds repeat thorugh . to other packages
Plug 'tpope/vim-speeddating'          " Dates in vim

" GUI enhancements
Plug 'yggdroot/indentline'            " Shows indentation levels
Plug 'tpope/vim-eunuch'               " Unix helpers
Plug 'machakann/vim-highlightedyank'  " Highlight yanks
Plug 'andymass/vim-matchup'           " Highlight corresponding blocks e.g. if - fi in bash
Plug 'itchyny/lightline.vim'		  " Better Status Bar
Plug 'mhinz/vim-startify'             " Better start screen
Plug 'scrooloose/nerdtree'			  " File Explorer
Plug 'jackguo380/vim-lsp-cxx-highlight'         " CXX Syntax Highlight for CoC.vim
Plug 'luochen1990/rainbow'              " Rainbow parentheses
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'                 " Both for fzf fuzzy search


" Git GUI
" Plug 'airblade/vim-gitgutter'         " Git gutter
Plug 'tpope/vim-fugitive'			  " Git Interface
Plug 'xuyuanp/nerdtree-git-plugin'

" Syntactic language support
Plug 'w0rp/ale'                        " Linting engine
Plug 'maximbaz/lightline-ale'          " Lightline + Ale
Plug 'plasticboy/vim-markdown'         " Markdown support
Plug 'cespare/vim-toml'                " TOML support
Plug 'stephpy/vim-yaml'                " YAML support
Plug 'elzr/vim-json'                   " Better JSON support
Plug 'rust-lang/rust.vim'              " Rust support
Plug 'glench/vim-jinja2-syntax'        " Jinja2 support
Plug 'lervag/vimtex'                   " Latex support
Plug 'pearofducks/ansible-vim'         " Ansible support
Plug 'mechatroner/rainbow_csv'         " CSV color coding
Plug 'ap/vim-css-color'                " CSS colors
Plug 'frazrepo/vim-rainbow'                " Rainbow parentheses
Plug 'vim-pandoc/vim-pandoc'           " Pandoc support
Plug 'vim-pandoc/vim-pandoc-syntax'    " Pandoc syntax
Plug 'chrisbra/colorizer'              " Colorize color codes
Plug 'liuchengxu/vista.vim'
" Plug 'vim-python/python-syntax'


" List ends here. Plugins become visible to Vim after this call.
call plug#end()


" *********** Configure LightLine ************
set laststatus=2
set noshowmode
" Function for CoC status
function! CocCurrentFunction()
    return get(b:, 'coc_current_function', '')
endfunction


function! StatusDiagnostic() abort
  let info = get(b:, 'coc_diagnostic_info', {})
  if empty(info) | return '' | endif
  let msgs = []
  if get(info, 'error', 0)
    call add(msgs, 'E' . info['error'])
  endif
  if get(info, 'warning', 0)
    call add(msgs, 'W' . info['warning'])
  endif
  return join(msgs, ' ') . ' ' . get(g:, 'coc_status', '')
endfunction

    function! LightlineFilename()
      return expand('%:t') !=# '' ? @% : '[No Name]'
    endfunction


let g:lightline = {
      \ 'colorscheme': 'onehalfdark',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             ['CocStatusDiag', 'currentfunction', 'readonly', 'filename', 'modified', 'fugitive'] ],
      \   'right': [ [ 'lineinfo' ],
      \              [ 'percent' ],
      \              [ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_ok', 'filetype', 'fileencoding'] ]
      \ },
      \ 'component_function': {
      \   'CocStatusDiag': 'StatusDiagnostic',
      \   'currentfunction': 'CocCurrentFunction',
      \   'filename': 'LightlineFilename'
      \ },
      \ }

let g:lightline.component_expand = {
      \  'linter_checking': 'lightline#ale#checking',
      \  'linter_infos': 'lightline#ale#infos',
      \  'linter_warnings': 'lightline#ale#warnings',
      \  'linter_errors': 'lightline#ale#errors',
      \  'linter_ok': 'lightline#ale#ok',
      \ }

" ALE
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set this variable to 1 to fix files when you save them.
let g:ale_enabled = 1
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 1
let g:ale_fixers = {
    \   '*': ['remove_trailing_lines', 'trim_whitespace'],
    \}
nmap <silent> [a <Plug>(ale_previous_wrap)
nmap <silent> ]a <Plug>(ale_next_wrap)


"*********** Interface ColorScheme *************
" "==> OneHalf Colors : Dark/Light
syntax on
set termguicolors
set t_Co=256
set cursorline
colorscheme onehalfdark

" ==> Molokai Colors
" let g:molokai_original = 1
" colorscheme molokai

" "==> Ayu Colors
" let ayucolor="mirage"   " for dark version of theme
" colorscheme ayu

"==> Grvbox Dark Colors
" set bg=dark
" colorscheme gruvbox

" " ==> Tender Colors
" if (has("termguicolors"))
"  set termguicolors
" endif

" syntax on
" colorscheme tender

" "==> OneDark Colors
" syntax on
" colorscheme onedark

" "==> VimOne Colors
" set background=dark       " for the dark version
" let g:one_allow_italics = 1 " I love italic for comments
" colorscheme one


" ********** Rainbow Parentheses ***********
let g:rainbow_active = 1    " Enable on Startup

"************ NERDTree Config ***********
" Close vim if only window left is NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Key Bindings for NERDTree
nnoremap <Leader>n :NERDTreeToggle<CR>
nnoremap <Leader>f :NERDTreeFind<CR>

" *************** FZF file search ***************
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

" [[B]Commits] Customize the options used by 'git log':
let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'

nnoremap <C-p> :GFiles <CR>

" ************ Kite ***********
" set completeopt+=menuone   " show the popup menu even when there is only 1 match
" set completeopt+=noinsert  " don't insert any text until user chooses a match
" set completeopt-=longest   " don't insert the longest common text

" let g:kite_tab_complete=1 " Insert completion with <Tab> as well!

" autocmd CompleteDone * if !pumvisible() | pclose | endif "Close preview window after completion inserted!

"Conquer of Completion
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if isdirectory($HOME . "/.vim/plugged/coc.nvim")

    " Use autocmd to force lightline update.
    autocmd User CocStatusChange,CocDiagnosticChange call lightline#update()

    " Use tab for trigger completion with characters ahead and navigate.
    " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
    " other plugin before putting this into your config.
    inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
    inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

    " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
    " position. Coc only does snippet and additional edit on confirm.
    " <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
    inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

    " if hidden is not set, TextEdit might fail.
    set hidden

    " Some servers have issues with backup files
    set nobackup
    set nowritebackup

    " Better display for messages
    set cmdheight=2

    " You will have bad experience for diagnostic messages when it's default 4000.
    set updatetime=300

    " don't give |ins-completion-menu| messages.
    set shortmess+=c

    " Always show the signcolumn, otherwise it would shift the text each time
    " diagnostics appear/become resolved.
    if has("patch-8.1.1564")
      " Recently vim can merge signcolumn and number column into one
      set signcolumn=number
    else
      set signcolumn=yes
    endif

    " Use <c-space> to trigger completion.
    if has('nvim')
      inoremap <silent><expr> <c-space> coc#refresh()
    else
      inoremap <silent><expr> <c-@> coc#refresh()
    endif

    " Use <C-j> for jump to next placeholder, it's default of coc.nvim
    " let g:coc_snippet_next = '<C-j>'

    " Use <C-k> for jump to previous placeholder, it's default of coc.nvim
    " let g:coc_snippet_prev = '<C-k>'

    " GoTo code navigation.
    nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gr <Plug>(coc-references)

    " Use K to show documentation in preview window.
    nnoremap <silent> K :call <SID>show_documentation()<CR>

    function! s:show_documentation()
      if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
      else
        call CocAction('doHover')
      endif
    endfunction

    " Use `[g` and `]g` to navigate diagnostics
    " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
    nmap <silent> [g <Plug>(coc-diagnostic-prev)
    nmap <silent> ]g <Plug>(coc-diagnostic-next)

    " Highlight the symbol and its references when holding the cursor.
    autocmd CursorHold * silent call CocActionAsync('highlight')
endif


" *********** Term Debugger ************
let g:termdebug_wide = 1

"Searching
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set incsearch           " search as characters are entered
set hlsearch            " highlight matches
set ignorecase          " Ignore case in searches by default
set smartcase           " But make it case sensitive if an uppercase is entered

" ********** Misc Configs ***********

set number				" Show Line Numbers
set rnu					" set relative line numbering
set showcmd             " show command in bottom bar
set cursorline          " highlight current line
filetype plugin on      " load filetype specific plugin files
set wildmenu            " visual autocomplete for command menu
set mouse+=a            " A necessary evil, mouse support
set splitbelow          " Open new vertical split bottom
set splitright          " Open new horizontal splits right
set scrolloff=5         " Keep cursor in approximately the middle of the screen
set ttyfast             " Improve redrawing
set signcolumn=auto     " Set the sign column to disappear when no signs to show for gitgutter and CoC
set autochdir           " Set the cwd to whatever file is in view. Necessary for omni completion

let mapleader="<Space>"    " remap the Leader key to <Space>

" Press Space to turn off highlighting and clear any message already displayed.
nnoremap <silent> ' :nohlsearch<Bar>:echo<CR>

" Spaces & Tabs
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set tabstop=4           " number of visual spaces per TAB
set softtabstop=4       " number of spaces in tab when editing
set shiftwidth=4        " Insert 4 spaces on a tab
set expandtab           " tabs are spaces, mainly because of python

filetype indent on      " load filetype-specific indent files

" vimtex
let g:tex_flavor = "latex"

" =============================================================================
"   CUSTOM FUNCTIONS
" =============================================================================

" toggle between number and relativenumber
function! ToggleLineNumber()
    if(&relativenumber == 1)
        set norelativenumber
        set number
    else
        set relativenumber
    endif
endfunc

command! LineNumberToggle call ToggleLineNumber()
