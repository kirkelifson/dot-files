function __lmstudio_probe --description "Probe an LM Studio /v1 endpoint and list served models"
    set -l url $argv[1]
    set -l body (curl -s --max-time 3 $url/models 2>/dev/null)
    if test -n "$body"
        echo "Reachable at $url:"
        echo "$body" | jq -r '.data[].id' 2>/dev/null | sed 's/^/  - /' | sed 's/^  - $/  - (jq missing)/'
    else
        echo "UNREACHABLE: $url"
    end
end

function lmstudio --description "Show or retarget the LM Studio endpoint used by opencode, pi, and hermes"
    set -l opencode_cfg ~/.config/opencode/opencode.json
    set -l pi_cfg ~/.pi/agent/models.json

    if test (count $argv) -eq 0
        printf '%-10s %s\n' opencode (sed -n 's/.*"baseURL": "\([^"]*\)".*/\1/p' $opencode_cfg 2>/dev/null | head -1)
        printf '%-10s %s\n' pi (sed -n 's/.*"baseUrl": "\([^"]*\)".*/\1/p' $pi_cfg 2>/dev/null | head -1)
        printf '%-10s %s\n' hermes (hermes config get providers.lmstudio.base_url 2>/dev/null)
        echo
        __lmstudio_probe (hermes config get providers.lmstudio.base_url 2>/dev/null)
        return 0
    end

    set -l new_url $argv[1]
    # Rewrite both dot-files configs in place (cat > follows the symlink into the repo).
    for file in $opencode_cfg $pi_cfg
        sed "s|\"baseURL\": \"[^\"]*\"|\"baseURL\": \"$new_url\"|; s|\"baseUrl\": \"[^\"]*\"|\"baseUrl\": \"$new_url\"|" $file > $file.tmp
        and cat $file.tmp > $file
        and rm -f $file.tmp
        or begin
            echo "Failed to update $file" >&2
            return 1
        end
    end
    hermes config set providers.lmstudio.base_url $new_url
    and set -Ux LMSTUDIO_BASE_URL $new_url
    echo "Retargeted opencode, pi, hermes -> $new_url"
    __lmstudio_probe $new_url
end
