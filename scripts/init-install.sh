#!/usr/bin/env fish

sudo apt update
sudo apt install vim git terminator vim-gtk3 curl \
    exuberant-ctags cscope gcc make pkg-config    \
    clang-format ripgrep clang

# fish-nvm
omf install https://github.com/fabioantunes/fish-nvm
omf install https://github.com/edc/bass

# agnoster
omf install agnoster

# vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# node for rust-analyzer
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
nvm install node

# Rust
curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh

# Install rust-analyzer
rustup component add rust-analyzer

# Install lean-ctx for AI token saving
# You may want to run `lean-ctx doctor` after this to check if everything
# is set up correctly, and `source ~/.config/fish/config.fish` to reload
# the config.
cargo install lean-ctx
lean-ctx setup

# Config vim for plugin
# vim
#:PlugInstall
#:CocInstall coc-rust-analyzer
#:CocInstall coc-clangd
#:CocInstall coc-lists
#:CocCommand clangd.install
#:Copilot setup
