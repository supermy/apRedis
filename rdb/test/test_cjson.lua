--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 21:01
-- To change this template use File | Settings | File Templates.
--
-------简单数据-------

local tab ={}
tab["Himi"] = "himigame.com"
--数据转json
local cjson = require "cjson"
local jsonData = cjson.encode(tab)

print(jsonData)
-- 打印结果:  {"Himi":"himigame.com"}

--json转数据
local data = cjson.decode(jsonData)

print(data.Himi)
-- 打印结果:  himigame.com


