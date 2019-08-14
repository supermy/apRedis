--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/14
-- Time: 08:19
-- To change this template use File | Settings | File Templates.
-- lua中高效判断数组(table)中是否存在某个字符值
-- 用数据值构建一个字典文件
-- redis-cli --ldb --eval lua/test_array.lua
-- 遍历数组
local function IsInTable(value, tbl)
    for k,v in ipairs(tbl) do
        if v == value then
            return true;
        end
    end
    return false;
end

--这个效率更高
local function revtab(tab)
    local revtabdata = {}
    for k, v in pairs(tab) do
        print(k,v)
        revtabdata[v] = true
    end
    return revtabdata
end

local tab = {'aid', 'bid', 'cid', 'did', 'eid', 'fid', 'gid', 'hid', 'jid', 'kid', 'lid'}
local newtab = revtab(tab)

--进行一万次索引用时统计
local t2 = redis.call('time')
local check = nil
for i=1,10000 do
    check = newtab['fid']
end
local t3 = redis.call('time')

return ('cost time:'..(t3[2]-t2[2]))
--return t2

--local tab1 = cjson.encode(tab)
--local tab2 = cjson.decode(tab1)
--return tab2['bid']