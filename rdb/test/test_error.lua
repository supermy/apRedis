--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/14
-- Time: 12:31
-- To change this template use File | Settings | File Templates.
--
local function myfunction ()
    n = n/nil
end

local function myerrorhandler( err )
    print( "ERROR:", err )
end

status = xpcall( myfunction, myerrorhandler )
print( status)


