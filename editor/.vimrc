set nocompatible

" vim-plug "
call plug#begin('~/.vim/autoload')
Plug 'morhetz/gruvbox'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'ackyshake/VimCompletesMe'
call plug#end()

" general vim setting "
syntax on
set number
set ruler
set showcmd
set showmatch
set shiftwidth=4

" gruvbox colorscheme "
colorscheme gruvbox
set background=dark

" trailing space showing "
highlight RedundantSpaces ctermbg=red guibg=red
match RedundantSpaces /\s\+$/

" airline status bar setting "
let g:airline_theme='simple'
let g:airline#extensions#branch#enabled=1

if has('autocmd') && v:version > 701
    " rusty-tags "
    autocmd BufRead *.rs :setlocal tags=./rusty-tags.vi;/

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
    " use both cscope and ctag for 'ctrl-]', ':ta', and 'vim -t'
    set cscopetag

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
endif
