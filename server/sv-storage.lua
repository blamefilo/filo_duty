Storage = {}

local function EnsureTable()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `filo_duty` (
            `uuid`       VARCHAR(32)  NOT NULL,
            `data`       LONGTEXT     NOT NULL,
            `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`uuid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(result)
        if result then
            DebugPrint("[filo_duty] Table ready.")
        else
            print("^1[filo_duty] ERROR: Failed to create filo_duty table.^7")
        end
    end)
end

function Storage:initialize()
    EnsureTable()
end

function Storage:get()
    local result = MySQL.query.await(
        "SELECT data FROM `filo_duty`",
        {}
    )
    if not result then return {} end

    local duties = {}
    for _, row in ipairs(result) do
        local ok, decoded = pcall(json.decode, row.data)
        if ok and decoded then
            duties[#duties + 1] = decoded
        end
    end

    return duties
end

function Storage:add(duty)
    if not duty.uuid then
        duty.uuid = Storage:generateUUID()
    end

    MySQL.query(
        "INSERT INTO `filo_duty` (uuid, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)",
        { duty.uuid, json.encode(duty) }
    )
end

function Storage:remove(uuid)
    MySQL.query(
        "DELETE FROM `filo_duty` WHERE uuid = ?",
        { uuid }
    )
end

function Storage:generateUUID()
    return lib.string.random('aaa111AAA111')
end
