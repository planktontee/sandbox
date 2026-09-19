# ---------------------------------------------------------------------------
# History: effectively unlimited, shared across sessions, deduped
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=999999999
SAVEHIST=999999999
setopt EXTENDED_HISTORY          # timestamp + duration per entry
setopt INC_APPEND_HISTORY_TIME   # write each command as it finishes
setopt SHARE_HISTORY             # see other sessions' commands
setopt HIST_IGNORE_ALL_DUPS      # keep only the newest copy of a duplicate
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE         # commands starting with a space aren't saved
setopt HIST_VERIFY               # expand !! etc. before running

# ---------------------------------------------------------------------------
# General options
# ---------------------------------------------------------------------------
setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP
setopt PROMPT_SUBST
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'   # alt+arrow word motion stops at / like bash
export EDITOR=nvim VISUAL=nvim
# the sandbox launcher clears the env; without a UTF-8 locale zsh/nvim/ls mangle non-ASCII
export LANG=${LANG:-en_US.UTF-8}

alias ll='ls -lah --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# ---------------------------------------------------------------------------
# Key bindings (emacs mode). kitty sends CSI 1;3X for alt+arrow and CSI 1;5X
# for ctrl+arrow; zsh binds neither by default, which is why they printed as
# literal escape codes.
# ---------------------------------------------------------------------------
bindkey -e
bindkey '^[[1;3C' forward-word         # alt+right
bindkey '^[[1;3D' backward-word        # alt+left
bindkey '^[[1;5C' forward-word         # ctrl+right
bindkey '^[[1;5D' backward-word        # ctrl+left
bindkey '^[^[[C'  forward-word         # alt+right (ESC-prefixed variant)
bindkey '^[^[[D'  backward-word        # alt+left  (ESC-prefixed variant)
bindkey '^[[1;3A' beginning-of-line    # alt+up
bindkey '^[[1;3B' end-of-line          # alt+down
bindkey '^[[H'    beginning-of-line    # home
bindkey '^[[F'    end-of-line          # end
bindkey '^[[1~'   beginning-of-line
bindkey '^[[4~'   end-of-line
bindkey '^[[3~'   delete-char          # delete
bindkey '^[[3;3~' kill-word            # alt+delete
bindkey '^[[3;5~' kill-word            # ctrl+delete
bindkey '^H'      backward-kill-word   # ctrl+backspace (kitty sends ^H)
bindkey '^[[Z'    reverse-menu-complete # shift+tab
bindkey '^[^M'    accept-line           # shift+enter: kitty is mapped to send ESC CR (for claude code through tmux)
bindkey '^[[A'    history-beginning-search-backward   # up: prefix search
bindkey '^[[B'    history-beginning-search-forward    # down

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
fpath=("$HOME/.zsh/plugins/fzf-tab" $fpath)
autoload -Uz compinit
# only re-scan completions once a day (speeds up startup)
if [[ -n "$HOME/.zcompdump"(#qN.mh+24) ]]; then compinit; else compinit -C; fi
zmodload zsh/complist
setopt COMPLETE_IN_WORD ALWAYS_TO_END AUTO_MENU AUTO_LIST
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/compcache"
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# ---------------------------------------------------------------------------
# fzf: ctrl+r history, ctrl+t files, alt+c cd; fzf-tab for completion menus
# ---------------------------------------------------------------------------
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:wrap --bind '?:toggle-preview'"
source "$HOME/.zsh/fzf-key-bindings.zsh"  # patched copy of /usr/share/fzf/key-bindings.zsh (sandbox can't setgroups)
source "$HOME/.zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
zstyle ':fzf-tab:*' fzf-flags --height=40%
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath'
zstyle ':fzf-tab:complete:z:*'  fzf-preview 'ls --color=always $realpath'

eval "$(zoxide init zsh)"

# ---------------------------------------------------------------------------
# Autosuggestions (fish-style, accept with → or ctrl+e / ctrl+f)
# ---------------------------------------------------------------------------
source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# ---------------------------------------------------------------------------
# Prompt: [exit code] [duration] user@host cwd (branch) #
# ---------------------------------------------------------------------------
autoload -Uz add-zsh-hook
typeset -g _cmd_start=0 _cmd_elapsed=''
_prompt_preexec() { _cmd_start=$EPOCHREALTIME; }
_prompt_precmd() {
    local rc=$?
    _cmd_elapsed=''
    if (( _cmd_start )); then
        local d=$(( EPOCHREALTIME - _cmd_start ))
        _cmd_start=0
        if   (( d >= 3600 )); then _cmd_elapsed=$(printf '%dh%02dm' $((d/3600)) $((d%3600/60)))
        elif (( d >= 60 ))   then _cmd_elapsed=$(printf '%dm%02ds' $((d/60)) $((d%60)))
        elif (( d >= 1 ))    then _cmd_elapsed=$(printf '%.1fs' $d)
        fi
        # colour is baked in here: nesting %F{..} inside ${..:+..} confuses PROMPT_SUBST
        [[ -n $_cmd_elapsed ]] && _cmd_elapsed=" %F{yellow}${_cmd_elapsed}%f"
    fi
    return $rc
}
zmodload zsh/datetime
add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd  _prompt_precmd


# git branch in prompt if inside a repo
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats ' %F{magenta}(%b)%f'
zstyle ':vcs_info:*' enable git
_vcs_precmd() { vcs_info; }
add-zsh-hook precmd _vcs_precmd
# %(?..) = "if exit status is 0 ... else ..."; %? is the last exit code.
# ASCII only: fancy glyphs have unreliable widths and confuse zle's cursor math.
PROMPT='%(?.%F{green}[0]%f.%F{red}[%?]%f)${_cmd_elapsed} %F{cyan}%n@%m%f %F{blue}%~%f${vcs_info_msg_0_} %# '
RPROMPT=''

# ---------------------------------------------------------------------------
# Syntax highlighting: must be sourced last
# ---------------------------------------------------------------------------
source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
