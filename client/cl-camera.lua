local cam = nil

---Creates and activates a scripted camera positioned at the target wheel.
---The local ped is hidden for the duration.
---@param vehicle  integer  Vehicle entity handle
---@param wheelBone string  Bone name (e.g. "wheel_lf")
local function createCamera(vehicle, wheelBone)
    local boneIndex = GetEntityBoneIndexByName(vehicle, wheelBone)
    if boneIndex == -1 then return end

    local offset   = WHEEL_BONES[wheelBone]
    local camPos   = GetOffsetFromEntityInWorldCoords(vehicle, offset.x, offset.y, offset.z)
    local wheelPos = GetWorldPositionOfEntityBone(vehicle, boneIndex)

    -- Blend out any existing scripted camera before creating a new one
    RenderScriptCams(false, true, 1000, true, false)
    if DoesCamExist(cam) then
        DestroyCam(cam, false)
        cam = 0
    end

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamActive(cam, true)
    SetCamCoord(cam, camPos.x, camPos.y, wheelPos.z)
    PointCamAtCoord(cam, wheelPos.x, wheelPos.y, wheelPos.z)
    RenderScriptCams(true, true, 1000, true, true)

    FreezeEntityPosition(cache.ped, true)
    SetEntityCollision(cache.ped, false)
    SetEntityAlpha(cache.ped, 0)
end

---Destroys the scripted camera and restores the gameplay camera + ped visibility.
local function deleteCamera()
    local gameplayCamPos = GetGameplayCamCoord()
    RenderScriptCams(false, true, 1000, gameplayCamPos, false)

    if DoesCamExist(cam) then
        DestroyCam(cam, false)
        cam = 0
    end

    SetEntityCollision(cache.ped, true)
    FreezeEntityPosition(cache.ped, false)
    ResetEntityAlpha(cache.ped)
end

return {
    create = createCamera,
    delete = deleteCamera,
}
