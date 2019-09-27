--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/9/25
-- Time: 21:54
-- To change this template use File | Settings | File Templates.
--
local s, e = string.find("Hello:Lua:user", ":", 1) --7指定查找的开始位置
print(s, e)


local s1, e1 = string.find("Hello,Lua,user", ",") --7指定查找的开始位置
print(s1, e1)
