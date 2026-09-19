# Sourced by every zsh, interactive or not. Pin PATH here: tmux sessions started
# from a host client don't reliably inherit the sandbox launcher's PATH.
typeset -U path
path=("$HOME/.local/bin" /usr/local/bin /usr/bin /bin $path)
export PATH
