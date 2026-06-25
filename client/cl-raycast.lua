---Fires a shape-test probe from the screen cursor and yields until a result arrives.
---@param flag       integer  Intersection flags (511 = all)
---@param distance   number   Max probe distance in world units
---@param ignoreEntity integer|nil Entity handle to exclude from the test
---@return boolean   hit          Whether the probe hit something
---@return integer   entityHit    Handle of the entity that was hit (0 if none)
---@return vector3   endCoords    World-space position of the hit point
local function raycastFromCursor(flag, distance, ignoreEntity)
    local screenX, screenY = GetDisabledControlNormal(0, 239), GetDisabledControlNormal(0, 240)
    local coords, normal   = GetWorldCoordFromScreenCoord(screenX, screenY)
    local destination      = coords + normal * (distance or 10.0)

    local handle           = StartShapeTestLosProbe(
        coords.x, coords.y, coords.z,
        destination.x, destination.y, destination.z,
        flag or 511, ignoreEntity or cache.ped, 7
    )

    while true do
        Wait(0)
        local retval, hit, endCoords, surfaceNormal, materialHash, entityHit =
            GetShapeTestResultIncludingMaterial(handle)

        if retval ~= 1 then
            return hit == 1, entityHit, endCoords
        end
    end
end

return raycastFromCursor
