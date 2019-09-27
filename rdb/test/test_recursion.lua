--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/9/20
-- Time: 23:05
-- To change this template use File | Settings | File Templates.
-- 递归

local fact
function fact(n)
    print(n)
    if n == 0 then
        return 1
    else
        return n*fact(n-1)
    end
end


fact(100)
