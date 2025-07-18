if status is-interactive
    # Commands to run in interactive sessions can go here
    set -gx PATH /usr/local/go/bin $PATH
end

# pyenv setup
set -gx PYENV_ROOT $HOME/.pyenv
set -gx PATH $PYENV_ROOT/bin $PATH

# initialize pyenv
status --is-interactive; and source (pyenv init -|psub)

# initialize pyenv-virtualenv (if using it)
status --is-interactive; and source (pyenv virtualenv-init -|psub)

# pywal
cat ~/.cache/wal/sequences

# run cursor detached

function cursordetach
	set folder "."
	if test (count $argv) -ge 1
		set folder $argv[1]
	end
	command cursor $folder </dev/null >/dev/null 2>&1 & disown
end
