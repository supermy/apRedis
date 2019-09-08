--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/9/6
-- Time: 12:51
-- To change this template use File | Settings | File Templates.
-- redis-cli --raw --eval rdb/test/test_redis_cjson.lua
-- 必须双引号

redis.log(redis.LOG_DEBUG,'测试 redis 环境下的 json 格式 begin')

local json = {}
json.a=1
json.b='a'
local jsonstr = cjson.encode(json)

redis.log(redis.LOG_DEBUG,jsonstr)

local jsonb = cjson.decode(jsonstr)
redis.log(redis.LOG_DEBUG,jsonb)

redis.log(redis.LOG_DEBUG,'测试 redis 环境下的 json 格式 end')
