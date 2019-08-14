--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 10:32
-- To change this template use File | Settings | File Templates.
-- redis-cli --ldb --eval lua/test.lua mykey somekey , 101 108
-- redis-cli --ldb --eval lua/test.lua 0 , 101 108

--用redis.debug() 可以打日志
--用redis.breakpoint()在lua脚本里打断点
--s和n都是跳到下行代码
--c是跳到下个断点
--list可以展示当前这条代码前后的代码
local key1 = KEYS[1]
local key2 = KEYS[2]
redis.debug(key1)
redis.debug(key2)
local value1 = ARGV[1]
local value2 = ARGV[2]
redis.debug(value1)
redis.debug(value2)
if(value1>value2)
then
    return "a"
else
    return "b"
end