
local lastStatusUpdate = 0

return {

    ['findClassesInBox'] = function(min, max, classes)
        local count = 1
        local find  = {}
        for _, class in ipairs( classes ) do
            for n, ent in ipairs( ents.FindByClass( class ) ) do
                local aabbmin, aabbmax = ent:WorldSpaceAABB()
                if aabbmin:WithinAABox(min, max) or aabbmax:WithinAABox(min, max) then
                    find[count] = ent
                    count = count + 1
                end
            end
        end
        return find
    end,

    ['vectorOp'] = function(v1, v2, f)
        return Vector( f(v1[1], v2[1]), f(v1[2], v2[2]), f(v1[3], v2[3]) )
    end,

    ['vectorRound'] = function(v1)
        v1[1] = math.Round(v1[1],6)
        v1[2] = math.Round(v1[2],6)
        v1[3] = math.Round(v1[3],6)
    end,

    ['printStatus'] = function(msg, prg, total)
        if (CurTime() - 0.25 > lastStatusUpdate) or (prg==total) then
            lastStatusUpdate = CurTime()
            chat.AddText( "dupe2obj: " .. msg .. " (" .. prg .. "/" .. total .. ")" )
        end
    end

}

