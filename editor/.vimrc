" rusty-tags "
autocmd BufRead *.rs :setlocal tags=./rusty-tags.vi;/

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
set nowrap
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

" keyword highlighting "
if has('autocmd') && v:version > 701
    augroup todo
        autocmd!
        autocmd Syntax * call matchadd(
                    \ 'Search',
                    \ '\v\W\zs<(NOTE|INFO|TODO|FIXME)>'
                    \ )
    augroup END
endif

