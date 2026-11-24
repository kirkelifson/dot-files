function __bt_decode_device --description 'Turn profile UUIDs into a plain-language device description'
    # Classic BT devices self-describe via standardized profile UUIDs
    # (A2DP Sink = "send me audio", HID = keyboard/mouse, ...); decode
    # the interesting ones into a one-line role summary.
    set -l uuids (string match -rg '^[[:space:]]*UUID: (.+)$' -- $argv)
    set -l roles
    for u in $uuids
        switch "$u"
            case '*Audio Sink*' '*A2DP*'
                contains -- 'audio output (A2DP sink)' $roles
                or set -a roles 'audio output (A2DP sink)'
            case '*Headset*' '*Handsfree*' '*Hands-Free*' '*Headphone*'
                contains -- 'headset — mic + audio' $roles
                or set -a roles 'headset — mic + audio'
            case '*Human Interface*' '*HID*'
                contains -- 'input device (HID)' $roles
                or set -a roles 'input device (HID)'
            case '*Battery*'
                contains -- 'reports battery' $roles
                or set -a roles 'reports battery'
            case '*Phonebook*' '*Message Access*'
                contains -- 'phone accessories access' $roles
                or set -a roles 'phone accessories access'
        end
    end
    if test (count $roles) -gt 0
        string join \n -- $roles
    end
end

