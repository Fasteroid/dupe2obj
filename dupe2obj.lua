

local SuperTable  = include("supertable.lua")     -- epic data structure
local vert_unfuck = include("vertexunfucker.lua") -- I hate bones
local helpers     = include("helpers.lua")        -- organization
local entmetas    = include("metamethods.lua")    -- NOTE: spawn your dupe AFTER running this script

local printStatus      = helpers.printStatus
local findClassesInBox = helpers.findClassesInBox
local vectorOp         = helpers.vectorOp
local vectorRound      = helpers.vectorRound

dupe2obj = dupe2obj or {

    classes        = { "prop_*", "gmod_*", "mediaplayer_*" }, -- classes to find

    header         = "# OBJ file generated by dupe2obj.lua\n" .. 
                     "# < github link here >\n" .. 
                     "o Garry's Mod\n",

    scale          = 1 / 52.49343832021, -- source units to meters

    textureQueue   = {}, -- don't touch

}
local textureQueue = dupe2obj.textureQueue

function dupe2obj.set1()
    dupe2obj.corner1 = LocalPlayer():GetEyeTrace().Entity or dupe2obj.corner1
end

function dupe2obj.set2()
    dupe2obj.corner2 = LocalPlayer():GetEyeTrace().Entity or dupe2obj.corner2
end

function dupe2obj.getFindBox()
    if not IsValid(dupe2obj.corner1) or not IsValid(dupe2obj.corner2) then return end
    local corner1 = dupe2obj.corner1:GetPos()
    local corner2 = dupe2obj.corner2:GetPos()
    local center = (corner1 + corner2) / 2
    local min = vectorOp( corner1, corner2, math.min ) 
    local max = vectorOp( corner1, corner2, math.max )
    center[3] = min[3]
    return min, max, center
end

function dupe2obj.generateObj(obj, center)

    local path = dupe2obj.savePath .. "/model.obj.txt"
    file.Write(path, dupe2obj.header)

    local batch = 0

    local temp = ""
    for id, vert in ipairs(obj.verts) do
        temp = temp .. "v " .. vert[1] .. " " .. vert[2] .. " " .. vert[3] .. "\n"
        batch = batch + 1
        if batch == 128 then 
            printStatus("writing verts",id,#obj.verts)
            file.Append(path, temp)
            temp = ""
            batch = 0
            coroutine.yield()
        end
    end

    file.Append(path, temp)

    temp = ""
    for id, uv in ipairs(obj.uvs) do
        temp = temp .. "vt " .. uv[1] .. " " .. uv[2] .. "\n"
        batch = batch + 1
        if batch == 128 then 
            printStatus("writing uvs",id,#obj.uvs)
            file.Append(path, temp)
            temp = ""
            batch = 0
            coroutine.yield()
        end
    end

    file.Append(path, temp)

    temp = ""
    for id, norm in ipairs(obj.normals) do
        temp = temp .. "vn " .. norm[1] .. " " .. norm[2] .. " " .. norm[3] .. "\n"
        batch = batch + 1
        if batch == 128 then 
            printStatus("writing normals",id,#obj.normals)
            file.Append(path, temp)
            temp = ""
            batch = 0
            coroutine.yield()
        end
    end

    file.Append(path, temp .. 's off\n')

    local count = 0
    for tex, ids in pairs(obj.tri_groups) do

        count = count + 1

        local facegroup = "usemtl " .. tex .. "\n"
        for i=1, #ids, 3 do
        
            local v3, v2, v1 = ids[i], ids[i+1], ids[i+2]

            facegroup = facegroup .. "f " ..
                v1.pos .. "/" .. v1.uv .. "/" .. v1.normal .. " " ..
                v2.pos .. "/" .. v2.uv .. "/" .. v2.normal .. " " .. 
                v3.pos .. "/" .. v3.uv .. "/" .. v3.normal .. "\n"

        end

        file.Append(path, facegroup)
        coroutine.yield()

        printStatus("writing face groups",count,obj.matcount)

    end

end

function dupe2obj.createLookupTable(obj)

    local verts   = obj.verts
    local normals = obj.normals
    local uvs     = obj.uvs

    local verts_lookup   = {}
    local normals_lookup = {}
    local uvs_lookup     = {}

    -- these tables are pretty sparse, so this isn't actually O(n^3) in the way it looks like it is
    chat.AddText("dupe2obj: merging verticies...")
    for x, _ in pairs(verts.data) do
        for y, _ in pairs(_) do
            for z, id in pairs(_) do
                verts_lookup[id] = {x, y, z}
            end
        end
    end

    chat.AddText("dupe2obj: merging normals...")
    for x, _ in pairs(normals.data) do
        for y, _ in pairs(_) do
            for z, id in pairs(_) do
                normals_lookup[id] = {x, y, z}
            end
        end
    end

    chat.AddText("dupe2obj: merging uvs...")
    for u, _ in pairs(uvs.data) do
        for v, id in pairs(_) do
            uvs_lookup[id] = {u, v}
        end
    end

    obj.verts   = verts_lookup
    obj.normals = normals_lookup
    obj.uvs     = uvs_lookup

end

function dupe2obj.addEntity(ent, obj, center)

    local submats = ent:GetTrueMaterials()
    local vismeshes, bindposes = util.GetModelMeshes( ent:GetModel() )

    local super_override = ent:GetMaterial()

    local verts   = obj.verts
    local normals = obj.normals
    local uvs     = obj.uvs

    local scale = ent:GetResizedScale()

    local tri_groups = obj.tri_groups

    for n, vismesh in ipairs(vismeshes) do

        local mat = (super_override ~= "" and super_override) or submats[n]
        if not tri_groups[mat] then obj.matcount = obj.matcount + 1 end
        tri_groups[mat] = tri_groups[mat] or {}
        
        local tris = tri_groups[mat]

        vert_unfuck(ent,vismesh,bindposes)

        for num, vert in ipairs(vismesh.triangles) do
            
            local pos = ent:WorldToLocal(vert.pos)
            pos = pos * scale
            pos = ent:LocalToWorld(pos)
            pos = pos - center
            pos = pos * dupe2obj.scale -- the lengths I had to go through for prop resizer... AHHHHHHasdfghjkl
            local norm = vert.normal

            vectorRound(pos)
            vectorRound(norm)

            local customvert = {}
            customvert.pos    = verts:add(pos[1], pos[2], pos[3])
            customvert.normal = normals:add(norm[1], norm[2], norm[3])
            customvert.uv     = uvs:add(vert.u, vert.v)
            table.insert(tris, customvert)

        end

    end

end

dupe2obj.uniqueID = dupe2obj.uniqueID or 0

function dupe2obj.processTextures()

    if #textureQueue < 1 then 
        hook.Remove("HUDPaint","dupe2obj.processTextures")
        return
    end

    local current = textureQueue[#textureQueue]

    -- render.SetRenderTarget( GetRenderTarget( "dupe2obj.scratchpad", current:Width(), current:Height() ) )
    render.DrawTextureToScreenRect(current, 0, 0, current:Width(), current:Height())
    local data = render.Capture( {
        format = "png",
        x = 0,
        y = 0,
        w = current:Width(),
        h = current:Height()
    } )

    file.Write( dupe2obj.savePath .. "/" .. current:GetName():Replace("/","-") .. ".png", data )

    table.remove(dupe2obj.textureQueue)

end


function dupe2obj.queueTextures(obj)

    table.Empty(textureQueue)
    local count = 0

    for tex, _ in pairs(obj.tri_groups) do

        mat = Material(tex)
        local bump = mat:GetTexture('$bumpmap')

        if bump then
            table.insert(textureQueue, bump)
        end

        table.insert(textureQueue, mat:GetTexture('$basetexture'))

        count = count + 1
        printStatus("compiling textures", count, obj.matcount)
        coroutine.yield()

    end

    hook.Add("HUDPaint","dupe2obj.processTextures",dupe2obj.processTextures)
    
end

function dupe2obj.saveInternal()

    local function doit()
        if not file.Exists( "dupe2obj", "DATA" ) then
            file.CreateDir("dupe2obj")
        end

        file.CreateDir(dupe2obj.savePath)

        local min, max, center = dupe2obj.getFindBox()
        local objents = findClassesInBox(min, max, dupe2obj.classes)

        table.RemoveByValue(objents, dupe2obj.corner1)
        table.RemoveByValue(objents, dupe2obj.corner2)

        local obj = {}

        obj.verts   = SuperTable.New3D()
        obj.normals = SuperTable.New3D()
        obj.uvs     = SuperTable.New2D()

        obj.tri_groups = {}

        obj.matcount = 0

        local count = #objents
        local batch = 0

        for id, ent in pairs(objents) do
            dupe2obj.addEntity(ent, obj, center)
            batch = batch + 1
            if batch > 16 then
                batch = 0
                printStatus("compiling entities", id, count)
                coroutine.yield()
            end
        end

        dupe2obj.createLookupTable(obj)

        dupe2obj.generateObj(obj, center)

        dupe2obj.queueTextures(obj)

    end

    xpcall( doit, function()
        chat.AddText( Color(255,120,100), debug.traceback() )
    end )

end


local co

function dupe2obj.save(path)
    dupe2obj.savePath = "dupe2obj/" .. (path or "untitled")
	co = coroutine.create( dupe2obj.saveInternal )
end

hook.Add( "Think", "dupe2obj.save", function()
    if co then
	    coroutine.resume(co)
    end
end )

----------------------------------------------------------------------

local wireframe = Material("models/wireframe")
local color = Color(0,255,255,255)
local nullang  = Angle(0,0,0)

hook.Remove("PostDrawOpaqueRenderables", "previewbox")
hook.Add( "PostDrawOpaqueRenderables", "previewbox", function()

    local min, max, center = dupe2obj.getFindBox()
    if not center then return end -- bail

    render.DrawWireframeBox(center, nullang, min-center, max-center, color, true)

end )
