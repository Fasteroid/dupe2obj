-- supertables: a fun data structure for hashing vectors by their actual position values opposed to memory locations

local SuperTable = {}

local function New2D()

    local this = {
        data = {},
        count = 0
    }
    local data = this.data

    function this:add(x, y)
        if not data[x] then data[x] = {} end
        local temp = data[x]
        if temp[y] == nil then
            self.count = self.count + 1
            temp[y] = self.count
            return self.count
        else
            return temp[y]
        end
    end

    return this

end
SuperTable.New2D = New2D

local function New3D()

    local this = {
        data = {},
        count = 0
    }
    local data = this.data

    function this:add(x, y, z)
        if not data[x] then data[x] = {} end
        local temp = data[x]
        if not temp[y] then temp[y] = {} end
        temp = temp[y]
        if temp[z] == nil then
            self.count = self.count + 1
            temp[z] = self.count
            return self.count
        else
            return temp[z]
        end
    end

    return this
end
SuperTable.New3D = New3D

return SuperTable
