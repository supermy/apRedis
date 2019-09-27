--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/9/24
-- Time: 20:36
-- To change this template use File | Settings | File Templates.
--

local function split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local abc='a|b|c|d'
local a = split(abc,"|")
local b =  split(abc,"|")
print('--------')
print(table.remove(b))
print(table.remove(b))
print(table.remove(b))
print(table.remove(b))
print(table.remove(b))
print(table.remove(b))

print('========')
print(table.remove(a,1))
print(table.remove(a,1))
print(table.remove(a,1))
print(table.remove(a,1))
print(table.remove(a,1))
print(table.remove(a,1))
