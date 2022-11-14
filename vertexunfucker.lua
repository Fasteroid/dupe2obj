local none = Vector(0,0,0)
local identity = Vector(1,1,1)

local function transformToBone(vert, trans_v, trans_n, weights, binds) -- special thanks to derpius for helping me fix the dreaded root bone rotated models

    local vf, nf = Vector(), Vector()

    for _, bone in pairs(weights) do
        if not trans_v[bone.bone] or not binds[bone.bone] then continue end

        local normal_bindmatrix = Matrix()
        normal_bindmatrix:Set( binds[bone.bone].matrix ) -- make a copy since we still want translation for positions!
        normal_bindmatrix:SetTranslation( none )         -- now get rid of translation... normals don't need it.

        trans_v[bone.bone]:SetScale( identity )      -- why does prop resizer SOMETIMES give these matricies scaling factors?
        binds[bone.bone].matrix:SetScale( identity ) -- don't really care, but it breaks my scaling code, so it's getting disabled.

        vf = vf + trans_v[bone.bone] * binds[bone.bone].matrix * vert.pos * bone.weight
        nf = nf + trans_n[bone.bone] * normal_bindmatrix * vert.normal * bone.weight
    end

    vert.pos = vf
    vert.normal = nf

end

local function GetBoneMatricies(ent)
    ent:SetupBones()
    local transform_v = {}
    local transform_n = {}
    for i = 0, ent:GetBoneCount() - 1 do
        local vert_transform = ent:GetBoneMatrix(i)
        local norm_transform = Matrix()
        norm_transform:Set( vert_transform )
        norm_transform:SetTranslation( none )

        transform_v[i] = vert_transform
        transform_n[i] = norm_transform
    end
    return transform_v, transform_n
end

local function vert_unfuck(ent, vismesh, bindposes) 

    local transform_v, transform_n = GetBoneMatricies(ent)

    for _, vert in pairs(vismesh.triangles) do
        if not vert.weights then continue end
        transformToBone(vert, transform_v, transform_n, vert.weights, bindposes)
        vert.weights = nil
    end

end

return vert_unfuck