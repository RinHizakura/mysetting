set nocompatible

" vim-plug "
call plug#begin('~/.vim/autoload')
Plug 'morhetz/gruvbox'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'basilgor/vim-autotags'
Plug 'vim-scripts/Mark'
Plug 'zivyangll/git-blame.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

" general vim setting "
syntax on
set number
set ruler
set showcmd
set showmatch
set hlsearch
set expandtab
set shiftwidth=4
set list
set listchars=tab:!·,trail:·

" gruvbox colorscheme "
colorscheme gruvbox
set background=dark

" trailing space showing "
highlight RedundantSpaces ctermbg=red guibg=red
match RedundantSpaces /\s\+$/

" airline status bar setting "
let g:airline_theme='simple'
let g:airline#extensions#branch#enabled=1

" show git blame"
:nnoremap <F7> :<C-u>call gitblame#echo()<CR>

" highlight without searching "
:nnoremap <F8> :let @/='\<<C-R>=expand("<cword>")<CR>\>'<CR>:set hls<CR>
:nnoremap <F9> :so types.vim<CR>

" add ctag from current path (for Rust)"
:nnoremap <F10> :set tags+=./tags,tags;<CR>

if has('autocmd') && v:version > 701
    " keyword highlighting "
    augroup todo
        autocmd!
        autocmd Syntax * call matchadd(
                    \ 'Search',
                    \ '\v\W\zs<(NOTE|INFO|TODO|FIXME)>'
                    \ )
    augroup END
endif

" cscope setting "
if has("cscope")
    " check cscope for definition of a symbol before checking ctags: set to 1
    " if you want the reverse search order.
    set csto=0

    " add any cscope database in current directory
    if filereadable("cscope.out")
        cs add cscope.out
    " else add the database pointed to by environment variable
    elseif $CSCOPE_DB != ""
        cs add $CSCOPE_DB
    endif

    " show msg when any other cscope db added
    set cscopeverbose

    nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-\>i :cs find i <C-R>=expand("<cfile>")<CR><CR>
endif


" coc.nvim "
" ref:
" - https://rust-analyzer.github.io/manual.html#vimneovim "
" - https://github.com/neoclide/coc.nvim                  "
set encoding=utf-8
set nobackup
set nowritebackup
set updatetime=300
set signcolumn=yes

inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" coc.list grep "
" ref:
" - https://github.com/neoclide/coc-lists "
" grep word under cursor "
command! -nargs=+ -complete=custom,s:GrepArgs Rg exe 'CocList grep '.<q-args>

function! s:GrepArgs(...)
  let list = ['-S', '-smartcase', '-i', '-ignorecase', '-w', '-word',
        \ '-e', '-regex', '-u', '-skip-vcs-ignores', '-t', '-extension']
  return join(list, "\n")
endfunction

" Keymapping for grep word under cursor with interactive mode "
nnoremap <silent> <Leader>cf :exe 'CocList -I --input='.expand('<cword>').' grep'<CR>

" vim-autotags "
let g:autotags_no_global = 1
let g:autotags_ctags_langmap = ""
let g:autotags_cscope_file_extensions = ".h .c .rs"
