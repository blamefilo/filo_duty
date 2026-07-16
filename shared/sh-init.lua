Bridge = exports.community_bridge:Bridge()

for key, value in pairs(Bridge) do
    if key ~= "Entity" and key ~= "MySQL" then
        load(key .. " = ...")(value)
    end
end

function DebugPrint(...)
    if Config.Debug then
        print(...)
    end
end
