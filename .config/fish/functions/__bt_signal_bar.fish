function __bt_signal_bar --description 'RSSI dBm → 4-bar strength indicator'
    set -l r $argv[1]
    if test -z "$r"
        return
    end
    set -l n 1
    if test $r -ge -55
        set n 4
    else if test $r -ge -70
        set n 3
    else if test $r -ge -85
        set n 2
    end
    echo (string repeat -n $n '▄')(string repeat -n (math 4 - $n) '▂')" $r dBm"
end

