function bt-watch --description 'Live signal strength for one Bluetooth device'
    # Usage: bt-watch AA:BB:CC:DD:EE:FF [seconds]   (default 30)
    # Streams RSSI updates as the device advertises; blank output means
    # it hasn't advertised since the last update (phones rest in background).
    set -l mac $argv[1]
    if test -z "$mac"
        echo "usage: bt-watch <MAC> [seconds]" >&2
        return 1
    end
    set -l secs 30
    if set -q argv[2]
        set secs $argv[2]
    end
    if not systemctl is-active --quiet bluetooth
        echo "bluetooth service is not running — sudo systemctl enable --now bluetooth" >&2
        return 1
    end
    echo "Watching $mac for $secs s ..."
    begin
        echo -e "scan on"
        sleep $secs
        echo -e "scan off"
        echo -e "quit"
    end | bluetoothctl 2>&1 | while read -l line
        if string match -rq "Device $mac RSSI: 0x[0-9a-fA-F]+ \(-[0-9]+\)" -- $line
            set -l r (string match -rg 'RSSI: 0x[0-9a-fA-F]+ \((-?[0-9]+)\)' -- $line)
            echo (date +%H:%M:%S)"  "(__bt_signal_bar $r)
        end
    end
end

