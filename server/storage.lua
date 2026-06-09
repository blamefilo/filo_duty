local data = {}
local storage = {}

local function CleanTable(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do
        res[CleanTable(k)] = CleanTable(v)
    end
    return res
end

function LoadBIN(file)
    local binaryData = LoadResourceFile(cache.resource, file, -1)
    if not binaryData or binaryData == "" then return {} end

    local success, myData = pcall(msgpack.unpack, binaryData)
    if not success then
        print("^1[Error]^7 vehicles.bin was corrupted or incomplete. Starting with fresh table.")
        return {}
    end
    return myData or {}
end

function SaveBIN(file, data)
    local cleanTable = CleanTable(data)
    local binaryBytes = msgpack.pack(cleanTable)
    SaveResourceFile(cache.resource, file, binaryBytes, #binaryBytes)
end

function storage:get()
    if not data then return {} end
    return LoadBIN('data/duties.bin')
end

function storage:set(newData)
    data = newData
    SaveBIN('data/duties.bin', newData)
end

function storage:add(duty)
    local duties = storage:get()
    table.insert(duties, duty)
    storage:set(duties)
end

function storage:remove(uuid)
    local duties = storage:get()
    for i, duty in ipairs(duties) do
        if duty.uuid == uuid then
            table.remove(duties, i)
            break
        end
    end
    storage:set(duties)
end

data = storage:get()
for _, duty in ipairs(data) do
    if not duty.uuid then
        duty.uuid = lib.string.random('aaa111AAA111')
    end
end
storage:set(data)

return {
    get = storage.get,
    set = storage.set,
    add = storage.add,
    remove = storage.remove
}