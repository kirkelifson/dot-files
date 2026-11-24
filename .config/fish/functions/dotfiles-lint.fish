function dotfiles-lint --description 'Run the dot-files CI lint suite locally (mirrors .github/workflows/lint.yml)'
    set -l repo ~/dot-files
    set -l fail 0

    # --- shellcheck: bash-shebang scripts in install + bin/ (same scope as CI) ---
    if type -q shellcheck
        set -l bash_scripts
        for f in $repo/install $repo/bin/*
            test -f $f; or continue
            string match -q -- '*bash*' (head -n1 $f); and set -a bash_scripts $f
        end
        if set -q bash_scripts[1]
            echo '==> shellcheck --severity=warning'
            shellcheck --severity=warning $bash_scripts; or set fail 1
        end
    else
        echo '==> shellcheck not installed - skipped (pacman -S shellcheck)'
        set fail 1
    end

    # --- fish -n over every fish file ---
    echo '==> fish -n'
    for f in (find $repo/.config/fish -name '*.fish' | sort)
        fish -n $f; or set fail 1
    end

    # --- Brewfile is a Ruby DSL ---
    if type -q ruby
        echo '==> ruby -c Brewfile'
        ruby -c $repo/Brewfile >/dev/null; or set fail 1
    else
        echo '==> ruby not installed - skipped (mise install ruby)'
        set fail 1
    end

    # --- actionlint over the workflows ---
    if type -q actionlint
        echo '==> actionlint'
        actionlint -color $repo/.github/workflows/*.yml; or set fail 1
    else
        echo '==> actionlint not installed - skipped (pacman -S actionlint)'
        set fail 1
    end

    # --- gitleaks over full git history, like the CI action ---
    if type -q gitleaks
        echo '==> gitleaks'
        gitleaks git $repo; or set fail 1
    else
        echo '==> gitleaks not installed - skipped (pacman -S gitleaks)'
    end

    if test $fail -eq 0
        echo 'dotfiles-lint: all checks passed'
    else
        echo 'dotfiles-lint: FAILURES found'
    end
    return $fail
end
