function fish_postexec --on-event fish_postexec
    if test $status -ne 0
        builtin history delete -- $argv[1]
        commandline -- $argv[1]
    end
end
