#!/usr/bin/env bash

sudo apt-add-repository ppa:fish-shell/release-4
sudo apt update
sudo apt install fish

# Default the shell to fish
chsh -s $(which fish)

# oh-my-fish
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
