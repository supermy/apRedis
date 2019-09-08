--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/9/7
-- Time: 16:54
-- To change this template use File | Settings | File Templates.

--1. redis-cli --eval script key_count key1,key2...arg1 argn
--2. redis-cli --evalsha scriptsha  key_count key1,key2...arg1 argn
--3. redis-cli eval "$(cat script.lua)" key_count key1,key2...arg1 arg2
--      key_count表示key参数的个数，在lua脚本中，可以通过KEYS+下标的方式引用;
--      argn表示参数，在lua脚本中可以通过ARGV+下标的方式引用;


-- redis-cli --raw --eval rdb/test/test_script.lua 2 user1 user2:list 1800
-- redis-cli --raw eval "$(cat rdb/test/test_script.lua)" 2 user1 user:list 1800
--
-- redis-cli --raw script load "$(cat rdb/test/test_script.lua)"
-- redis-cli --raw evalsha da7efa23d44192ca7e0ded4be8a4817ac450ad13 2 user1 user:list 1800

redis.log(redis.LOG_NOTICE,'test script......')

local result=0

redis.call('set', KEYS[1], '张三')

local id= redis.call('get',KEYS[1]) --查询 id

redis.call('sadd', 'user:list', id)

redis.log(redis.LOG_WARNING,id)

if id then
    result= redis.call('sismember', KEYS[2], id) --在好友列表中
    redis.log(redis.LOG_WARNING, result)
end

if result==1 then
    redis.call('expire',KEYS[1],ARGV[1])  --配置 key1 的有效期
end

return result