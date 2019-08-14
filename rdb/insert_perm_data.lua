--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 12:30
-- To change this template use File | Settings | File Templates.
-- ##维护 perm 数据；
-- redis-cli --ldb --eval lua/insert_perm_data.lua  id res , orgs user/orgs
--  hset sys_perms_data-orgs res user/orgs
local id = KEYS[1]
local idvalue = ARGV[1]
local res = KEYS[2]
local resvalue = ARGV[2]

redis.debug(id)
redis.debug(idvalue)
redis.debug(res)
redis.debug(resvalue)

--字段数，记录数 ？？？
--perm_cnt=redis.call('incr','sys_perms_count');
--redis.debug(perm_cnt)

-- set插入perm一条记录
redis.call('hset','sys_perms_data-'..idvalue,res,resvalue);

-- [或者考虑使用 hash ,看指令维护数据是否方便] set插入perm-ID;维护数据sscan myset1 0 match h*
redis.call('sadd','sys_perms_list','sys_perms_data-'..idvalue);

-- 数据库维护
redis.call('sadd','sys_rbac_list','sys_perms_data');

local result = {}
result.key = res;
result.value = resvalue;
--local result = redis.call('hget','sys_perms_data-'..idvalue,res);

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