--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/14
-- Time: 12:31
-- To change this template use File | Settings | File Templates.
-- redis-cli --raw --eval rdb/test/test_error.lua
--业务逻辑
local myfunction = function  (abc)
--    n = n/nil
--    error({code=211})
    return 'ok'
end

--异常处理函数
local function myerrorhandler( err )
    redis.log(redis.LOG_NOTICE,'error info ......')
    redis.log(redis.LOG_NOTICE,err.code)
--    redis.log(redis.LOG_NOTICE,debug.traceback())
    print( "ERROR:", err.code )
--    print( "ERROR:", debug.traceback() ) --错误跟踪
--    print( "ERROR:", debug.debug() ) 手动调试

end


--返回状态 myfunction如果带参数，xpcall 会产生错误
local status, msg = xpcall( myfunction(123), myerrorhandler )
print( status, msg)
redis.log(redis.LOG_NOTICE,status, msg)
