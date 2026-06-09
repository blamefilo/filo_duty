Bridge = exports.community_bridge:Bridge()

for key, value in pairs(Bridge) do
    load(key .. " = ...") (value)
end

function DebugPrint(...)
    if not Config.Debug then return end
    print('[Filo Duty] ' .. table.concat({...}, ' '))
end