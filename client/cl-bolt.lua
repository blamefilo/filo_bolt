local ROTATION_STEPS  = 1
local ROTATION_DEGREE = 360.0 / ROTATION_STEPS
local ROTATION_TICKS  = 100

local rotatingBolts   = {} ---@type table<integer, boolean>  bolt handle → in-progress flag
local rotatedBolts    = {} ---@type integer[]                ordered list of finished bolt handles
local spawnedBolts    = {} ---@type integer[]                all bolt handles for cleanup

---Requests a model and waits until it's loaded before returning.
---@param model integer  Joaat hash
---@return integer|nil model  Returns the hash on success, nil if not in cdimage
local function loadModel(model)
    if not IsModelInCdimage(model) then return nil end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    return model
end

---Animates a single bolt entity rotating around its Y-axis.
---Tightening rotates clockwise; loosening rotates counter-clockwise and then
---enables physics so the bolt can fall away.
---@param bolt        integer  Bolt entity handle
---@param isClockwise boolean  true = tighten, false = loosen
local function rotateBolt(bolt, isClockwise)
    if not DoesEntityExist(bolt) then return end
    if rotatingBolts[bolt] then return end -- already animating

    rotatingBolts[bolt] = true

    CreateThread(function()
        local frozenPos = GetEntityCoords(bolt)

        DetachEntity(bolt, false, false)
        FreezeEntityPosition(bolt, true)
        SetEntityCoordsNoOffset(bolt, frozenPos.x, frozenPos.y, frozenPos.z, false, false, false, false)

        local rot     = GetEntityRotation(bolt, 2)
        local startY  = rot.y
        local targetY = startY + (isClockwise and -ROTATION_DEGREE or ROTATION_DEGREE)
        PlaySound(bolt, 'ratchet')
        for tick = 1, ROTATION_TICKS do
            if not DoesEntityExist(bolt) then
                rotatingBolts[bolt] = nil
                return
            end

            local t    = tick / ROTATION_TICKS
            local newY = startY + (targetY - startY) * t
            local newZ = GetOffsetFromEntityInWorldCoords(bolt, 0.0, isClockwise and -0.00035 or 0.00035, 0.0)

            SetEntityCoordsNoOffset(bolt, newZ.x, newZ.y, frozenPos.z, false, false, false, false)
            SetEntityRotation(bolt, rot.x, newY, rot.z, 2)
            Wait(0)
        end

        SetEntityRotation(bolt, rot.x, targetY, rot.z, 2)
        FreezeEntityPosition(bolt, isClockwise)

        if not isClockwise then
            SetEntityCollision(bolt, true, true)
            ActivatePhysics(bolt)
        end

        Wait(200)
        rotatedBolts[#rotatedBolts + 1] = bolt
        rotatingBolts[bolt] = nil
    end)
end

---Spawns `lugnutCount` bolt entities evenly distributed around the given wheel bone.
---Each bolt is attached to the vehicle and registered for later cleanup.
---@param vehicle    integer  Vehicle entity handle
---@param wheelBone  string   Bone name (e.g. "wheel_lf")
---@param lugnutCount integer Number of bolts to spawn (default 5)
---@return table bolts      Array of `{ entity, offsetY, offsetZ }` tables
---@return integer boneIndex Bone index of the wheel
---@return number  side     WHEEL_SIDE value for this bone (-1.0 or 1.0)
local function createBolts(vehicle, wheelBone, lugnutCount)
    lugnutCount = lugnutCount or 5

    local boneIndex = GetEntityBoneIndexByName(vehicle, wheelBone)
    if boneIndex == -1 then return {}, boneIndex, -1.0 end
    if not loadModel(BOLT_MODEL) then return {}, boneIndex, -1.0 end

    local side      = WHEEL_SIDE[wheelBone] or -1.0
    local stepAngle = (2.0 * math.pi) / lugnutCount
    local heading   = GetEntityHeading(vehicle)
    local spawned   = {}

    for i = 0, lugnutCount - 1 do
        local angle        = stepAngle * i
        local offsetY      = BOLT_RADIUS * math.cos(angle)
        local offsetZ      = BOLT_RADIUS * math.sin(angle)

        local boltWorldPos = GetOffsetFromEntityInWorldCoords(
            vehicle,
            WHEEL_BONES[wheelBone].x + side * 0.02,
            WHEEL_BONES[wheelBone].y + offsetY,
            WHEEL_BONES[wheelBone].z + offsetZ
        )

        local bolt         = CreateObjectNoOffset(
            BOLT_MODEL,
            boltWorldPos.x, boltWorldPos.y, boltWorldPos.z,
            false, false, false
        )
        while not DoesEntityExist(bolt) do Wait(0) end

        SetEntityHeading(bolt, heading + (side > 0 and 90.0 or -90.0))

        AttachEntityToEntity(
            bolt, vehicle, boneIndex,
            side * 0.12, offsetY, offsetZ,
            0.0, 0.0, side > 0 and -90.0 or 90.0,
            false, false, true, false, 1, true
        )

        SetEntityNoCollisionEntity(bolt, vehicle, false)
        SetEntityAsMissionEntity(bolt, true, true)

        spawnedBolts[#spawnedBolts + 1] = bolt
        spawned[#spawned + 1] = { entity = bolt, offsetY = offsetY, offsetZ = offsetZ }
    end

    SetModelAsNoLongerNeeded(BOLT_MODEL)
    return spawned, boneIndex, side
end

---Deletes a list of bolt entity tables (`{ entity, ... }`).
---@param bolts table[]  Array of bolt tables returned by `createBolts`
local function deleteBolts(bolts)
    for _, bolt in ipairs(bolts) do
        if DoesEntityExist(bolt.entity) then
            SetEntityAsMissionEntity(bolt.entity, false, true)
            DeleteObject(bolt.entity)
        end
    end
end

---Deletes every bolt ever spawned by this module (used on resource stop).
local function deleteAllBolts()
    for _, entity in ipairs(spawnedBolts) do
        if DoesEntityExist(entity) then
            SetEntityAsMissionEntity(entity, false, true)
            DeleteEntity(entity)
        end
    end
    spawnedBolts = {}
end

---Clears the rotated-bolts tracker (call before each new minigame session).
local function resetRotatedBolts()
    rotatedBolts = {}
end

---Returns the current list of completed (rotated) bolt handles.
---@return integer[]
local function getRotatedBolts()
    return rotatedBolts
end

---Returns the number of bolts currently rotating.
---@return integer
local function getRotatingBoltsCount()
    local count = 0
    for _ in pairs(rotatingBolts) do
        count = count + 1
    end
    return count
end

local function isRotating(bolt)
    return bolt and rotatingBolts[bolt] ~= nil
end

local function isRotated(bolt)
    for _, rotated in ipairs(rotatedBolts) do
        if rotated == bolt then
            return true
        end
    end
    return false
end

return {
    rotate                = rotateBolt,
    create                = createBolts,
    delete                = deleteBolts,
    deleteAll             = deleteAllBolts,
    resetRotated          = resetRotatedBolts,
    getRotated            = getRotatedBolts,
    isRotating            = isRotating,
    getRotatingBoltsCount = getRotatingBoltsCount,
    isRotated             = isRotated,
    MODEL                 = BOLT_MODEL,
}
