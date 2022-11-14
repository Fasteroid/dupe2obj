local ENT = FindMetaTable("Entity")

dupe2obj_detours = dupe2obj_detours or {}

function ENT:GetTrueMaterials()
    local mats = self:GetMaterials()
    for id, mat in pairs( mats ) do
        local override = self:GetSubMaterial(id-1)
        mats[id] = (override ~= "" and override) or mats[id]
    end
    return mats
end

dupe2obj_detours.EnableMatrix = dupe2obj_detours.EnableMatrix or ENT.EnableMatrix
local EnableMatrix = dupe2obj_detours.EnableMatrix

function ENT:EnableMatrix( matrixType, matrix ) -- because for some reason there's no ENT:GetMatrix, wtf garry??
    if matrixType == "RenderMultiply" then
        self.RenderMultiply = matrix:GetScale()
    end
    EnableMatrix(self, matrixType, matrix)
end

function ENT:GetResizedScale()
    return self.RenderMultiply or Vector(1,1,1)
end