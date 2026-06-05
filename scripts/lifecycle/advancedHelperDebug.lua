advancedHelperDebug = {}

function advancedHelperDebug.log(msg)
    if advancedHelperConfig.DEBUG then
        print("[advancedHelper] " .. msg)
    end
end