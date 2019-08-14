--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 12:30
-- To change this template use File | Settings | File Templates.
-- ##维护 perm 数据；
-- redis-cli --ldb --eval lua/get_perm_data.lua  0 , orgs

local idvalue = ARGV[1]

redis.debug(idvalue)

-- set插入perm一条记录
local result =redis.call('hgetall','sys_perms_data-'..idvalue);

return cjson.encode(result);

--[[
    local id = redis.call('get',key)
    if(id == false)
    then
        redis.call('set',key,1)
        local key1=redis.call('get',key)
        redis.debug(key1)
        return key.."0001"
    else
        redis.call('set',key,id+1)
        return key..string.format('%04d',id + 1)
    end
--]]