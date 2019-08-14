--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 10:32
-- To change this template use File | Settings | File Templates.
-- redis-cli --ldb --eval lua/test.lua mykey somekey , 101 108
-- redis-cli --ldb --eval lua/test_get_set.lua mykey

--用redis.debug() 可以打日志
--用redis.breakpoint()在lua脚本里打断点
--s和n都是跳到下行代码
--c是跳到下个断点
--list可以展示当前这条代码前后的代码

local key = KEYS[1]
redis.debug(key)
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