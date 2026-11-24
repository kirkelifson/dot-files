function bt-scan --description 'Scan for nearby Bluetooth devices and show everything known about them'
    # Usage: bt-scan [seconds]   (default 15)
    # Real names only appear while a device is in pairing mode; privacy-
    # conscious devices (phones, watches) otherwise broadcast namelessly.
    set -l secs 15
    if set -q argv[1]
        set secs $argv[1]
    end

    if not systemctl is-active --quiet bluetooth
        echo "bluetooth service is not running — sudo systemctl enable --now bluetooth" >&2
        return 1
    end

    set -l tmp (mktemp)
    or return 1

    echo "Scanning for $secs s ..."
    begin
        echo -e "scan on"
        sleep $secs
        echo -e "scan off"
        sleep 1
        echo -e "quit"
    end | bluetoothctl >$tmp 2>&1

    # Devices around right now = seen during THIS scan ([NEW] or [CHG])
    # and still known to bluetoothd (re-scan re-emits [CHG], not [NEW]).
    set -l seen (string match -rag 'Device ([0-9A-F:]{17})' <$tmp | sort -u)
    set -l known (bluetoothctl devices | string match -rg 'Device ([0-9A-F:]{17})')
    set -l macs
    for m in $seen
        contains -- $m $known
        and set -a macs $m
    end
    set -l found 0

    for mac in $macs
        set -l info (bluetoothctl info $mac 2>/dev/null)
        # a vanished device answers with a single "not available" line
        if test (count $info) -lt 2
            continue
        end
        set found (math $found + 1)

        # name: the cached Name property, else whatever the scan heard
        set -l name (string match -rg '^[[:space:]]*Name: (.+)$' -- $info)
        if test -z "$name"
            set name (string match -rg "\[NEW\] Device $mac (.+)\$" <$tmp)
        end
        if test -n "$name"
            set name (string trim -- (string match -r '.+' -- $name)[1])
        end
        # discard "names" that are just the MAC rendered with dashes
        if test -n "$name"; and string match -qr '^[0-9A-F-]{17}$' -- $name
            set -e name
        end

        set -l header (string trim -- $info[1])
        if test -n "$name"
            set header "$header — $name"
        end
        echo "── $header"

        # decoded summary: what it is (profile UUIDs) + how strong (RSSI)
        set -l summary (__bt_decode_device $info)
        # most recent RSSI heard during the scan
        set -l rssi (string match -rg "Device $mac RSSI: 0x[0-9a-fA-F]+ \((-?[0-9]+)\)" <$tmp)
        test (count $rssi) -gt 0
        and set -a summary (__bt_signal_bar $rssi[-1])
        if test (count $summary) -gt 0
            echo "   ↳ "(string join ' · ' -- $summary)
        end

        for line in $info[2..-1]
            string match -q 'DBG:*' -- $line
            and continue
            echo "   "(string trim -- $line)
        end

        # unnamed but identifiable? name the vendor behind the beacon
        if test -z "$name"
            set -l mkey (string match -rg 'ManufacturerData\.Key: 0x0*([0-9A-Fa-f]+)' -- $info)
            set -l vendor (__bt_vendor_from_id "$mkey")
            if test -n "$vendor"
                echo "   Vendor: $vendor (manufacturer beacon 0x$(string lower -- $mkey))"
            end
        end
        echo
    end

    command rm -f $tmp

    if test $found -eq 0
        echo "No devices found — try longer: bt-scan 30"
        return 1
    end
    echo "$found device(s)"
end

