local Camera            = require("client/cl-camera")
local Bolt              = require("client/cl-bolt")
local raycastFromCursor = require("client/cl-raycast")

local isActive          = false
local p                 = nil

---Resolves a numeric bone index back to a bone name string.
---@param vehicle  integer
---@param boneIdx  integer
---@return string|nil
local function boneIndexToName(vehicle, boneIdx)
    for bone in pairs(WHEEL_BONES) do
        if GetEntityBoneIndexByName(vehicle, bone) == boneIdx then
            return bone
        end
    end
end

---Runs a persistent thread that captures mouse input while the minigame is active.
local function startInputCapture()
    CreateThread(function()
        while isActive do
            SetMouseCursorThisFrame()
            DisableAllControlActions(0)
            DisableAllControlActions(2)
            Wait(0)
        end
    end)
end

---Starts the bolt minigame for a given vehicle wheel.
---Blocks (via promise) until the player finishes or cancels.
---@param data table
---   .vehicle     integer   Vehicle entity handle  (required)
---   .wheelBone   string|integer  Bone name or bone index  (required)
---   .lugnutCount integer   How many bolts to spawn  (default 5)
---   .isTightening boolean  true = tighten, false = loosen  (default false)
---@return boolean  success  true if all bolts were rotated, false if cancelled
function Start(data)
    if isActive then return end
    if not data or not data.vehicle or not DoesEntityExist(data.vehicle) then return end
    if not data.wheelBone then return end

    -- Accept either a bone index or a bone name
    if type(data.wheelBone) == "number" then
        data.wheelBone = boneIndexToName(data.vehicle, data.wheelBone)
        if not data.wheelBone then return end
    end

    local canCancel = data.canCancel ~= nil and data.canCancel or true
    isActive        = true
    p               = promise.new()

    Bolt.resetRotated()

    CreateThread(function()
        -- Setup
        -- Camera.create(data.vehicle, data.wheelBone)
        local bolts = Bolt.create(data.vehicle, data.wheelBone, data.lugnutCount)
        Wait(500)

        -- Quick-access lookup: entity handle → bolt table
        local boltByEntity = {}
        for _, b in ipairs(bolts) do
            boltByEntity[b.entity] = b
        end

        startInputCapture()


        local lastEntityHit = nil
        local selectedBolt  = nil

        while isActive do
            local hit, entityHit = raycastFromCursor(511, 5.0, data.vehicle)

            if hit and entityHit and GetEntityType(entityHit) == 3 then
                local isBolt     = GetEntityModel(entityHit) == Bolt.MODEL
                local isRotating = false
                local isFinished = false

                if isBolt then
                    isRotating = Bolt.isRotating(entityHit)
                    isFinished = Bolt.isRotated(entityHit)
                end

                -- Clear outline on previously hovered entity when focus changes
                if lastEntityHit and lastEntityHit ~= entityHit then
                    SetEntityDrawOutline(lastEntityHit, false)
                end

                if isBolt then
                    if not isFinished then
                        if isRotating then
                            SetMouseCursorStyle(4)
                        else
                            SetMouseCursorStyle(5)
                        end
                        SetEntityDrawOutline(entityHit, true)
                        SetEntityDrawOutlineColor(Config.OutlineColor.r, Config.OutlineColor.g, Config.OutlineColor.b,
                            Config.OutlineColor.a)
                        lastEntityHit = entityHit
                        selectedBolt  = boltByEntity[entityHit]
                    else
                        SetMouseCursorStyle(2)
                        SetEntityDrawOutline(entityHit, false)
                        lastEntityHit = nil
                        selectedBolt  = nil
                    end
                else
                    -- Hovering a non-bolt object (e.g. wheel rim)
                    SetMouseCursorStyle(2)
                    lastEntityHit = entityHit
                    selectedBolt  = nil
                end
            else
                -- Nothing hit — clear outline
                if lastEntityHit then
                    SetEntityDrawOutline(lastEntityHit, false)
                    lastEntityHit = nil
                    selectedBolt  = nil
                end
                SetMouseCursorStyle(2)
            end

            -- Interact with selected bolt (LMB / Attack)
            if selectedBolt and IsDisabledControlPressed(2, 24) then
                if not (Config.OneAtATime and Bolt.getRotatingBoltsCount() > 0) then
                    Bolt.rotate(selectedBolt.entity, data.isTightening or false)
                end
            end

            -- Win condition
            if #Bolt.getRotated() >= (data.lugnutCount or 5) then
                p:resolve(true)
                break
            end

            if canCancel and (IsDisabledControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 73)) then
                p:resolve(false)
                break
            end

            Wait(0)
        end


        Camera.delete()
        Bolt.delete(bolts)
        isActive = false
    end)

    return Citizen.Await(p)
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Bolt.deleteAll()
end)

exports("Start", Start)

-- local options = {}
-- for bone in pairs(WHEEL_BONES) do
--     table.insert(options, {
--         label = "Bolt Test (" .. bone .. ")",
--         bones = { bone },
--         distance = 2.0,
--         onSelect = function(data)
--             local vehicle = data.entity
--             if not vehicle or not DoesEntityExist(vehicle) then return end
--             CreateThread(function()
--                 Start({ vehicle = vehicle, wheelBone = bone, lugnutCount = 6, isTightening = true })
--             end)
--         end,
--     })
-- end

-- exports.ox_target:addGlobalVehicle(options)
