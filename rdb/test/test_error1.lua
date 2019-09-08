--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/14
-- Time: 12:31
-- To change this template use File | Settings | File Templates.
--
local status, err = pcall(function () error({code=211}) end)
--local status, err = pcall(function () return 'ok' end)

print(status, err.code)