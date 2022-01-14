ctags --c-kinds=gstu -o- -R | awk '{printf("syntax keyword Type\t%s\n", $1)}' > types.vim
