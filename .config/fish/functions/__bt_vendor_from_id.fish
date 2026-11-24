function __bt_vendor_from_id --description 'Bluetooth SIG company ID → vendor name (partial)'
    switch (string lower -- "$argv[1]")
        case 4c
            echo Apple
        case 6
            echo Microsoft
        case 75
            echo Samsung
        case e1
            echo Google
        case 87
            echo Garmin
        case 171
            echo Amazon
    end
end

