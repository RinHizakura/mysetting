if status is-interactive
    # Commands to run in interactive sessions can go here
    bass source ~/.nvm/nvm.sh

    source "$HOME/.cargo/env.fish"
    set -x NVM_DIR ~/.nvm
end
