function fish_prompt
    # Save last status
    set -l last_status $status

    # Hostname in cyan
    set_color cyan
    echo -n (prompt_hostname)
    set_color normal
    echo -n ' '

    # Last 2 directories in gray
    set_color brblack
    echo -n (prompt_pwd --full-length-dirs 2)
    set_color normal
    echo -n ' '

    # Git branch and status
    if git rev-parse --git-dir >/dev/null 2>&1
        set -l branch (git branch --show-current 2>/dev/null)
        if test -z "$branch"
            # Detached HEAD
            set branch (git rev-parse --short HEAD 2>/dev/null)
        end

        # Check for staged and unstaged changes
        set -l git_status ""
        if not git diff --quiet 2>/dev/null
            set git_status "*"  # Unstaged changes
        end
        if not git diff --cached --quiet 2>/dev/null
            set git_status "$git_status+"  # Staged changes
        end

        # Display branch with status indicators
        set_color yellow
        echo -n "($branch$git_status)"
        set_color normal
        echo -n ' '
    end

    # Prompt character
    echo -n '> '
end
