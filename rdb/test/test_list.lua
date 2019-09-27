--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/9/20
-- Time: 23:11
-- To change this template use File | Settings | File Templates.
-- 队列
List = require('./rdb/test/list').new()

List:pushleft('a')
List.pushleft('b')
List.pushright('c')
List.pushright('d')

print(List.popleft())
print(List.popright())