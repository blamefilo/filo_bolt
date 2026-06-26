local hasTriggered = false
RegisterConsoleListener(function(channel, message)
    if hasTriggered then return end
    if channel ~= 'svadhesive' and channel ~= 'resources' then return end

    hasTriggered = true

    local resourceName = GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resourceName, 'version', 0)

    local apiUrl = ("https://filoversionchecker.vercel.app/api/check-version?resource=%s&version=%s")
        :format(resourceName, currentVersion)

    PerformHttpRequest(apiUrl, function(statusCode, text, headers)
        if statusCode ~= 200 or not text then return end

        local queued = json.decode(text)
        if not queued or not queued.resultKey then return end

        local pollUrl = ("https://filoversionchecker.vercel.app/api/get-result?key=%s")
            :format(queued.resultKey)

        SetTimeout(1500 + math.random(1000, 2000), function()
            if GlobalState.filo_checked then return end
            GlobalState.filo_checked = true

            PerformHttpRequest(pollUrl, function(pollStatus, pollText, _)
                if pollStatus ~= 200 or not pollText then return end

                local result = json.decode(pollText)
                if result and result.ready and result.text and #result.text > 0 then
                    print(result.text)
                end
            end, 'GET')
        end)
    end, 'GET')
end)
