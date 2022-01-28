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
set hlsearch
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

" highlight without searching
:nnoremap <F8> :let @/='\<<C-R>=expand("<cword>")<CR>\>'<CR>:set hls<CR>
:nnoremap <F9> :so types.vim<CR>

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

    nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
    nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
    nmap <C-\>i :cs find i <C-R>=expand("<cfile>")<CR><CR>
endif
