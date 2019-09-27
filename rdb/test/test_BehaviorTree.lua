--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/9/27
-- Time: 16:01
-- To change this template use File | Settings | File Templates.
-- 行为树比有限状态的几个优势：行为树提供了强大的灵活性，非常强大，并且很容易更改行为树的结构。
--[[
为行为树定义各种各样的控制节点（这也是行为树有意思的地方之一），一般来说，常用的控制节点有以下三种

选择（Selector）：选择其子节点的某一个执行
序列（Sequence）：将其所有子节点依次执行，也就是说当前一个返回“完成”状态后，再运行先一个子节点
并行（Parallel）：将其所有子节点都运行一遍
]]


local SELECTOR = 1
local SEQUENCE = 2
local CONDITION = 3
local ACTION = 4

cjson = require ('cjson')

local function Traverse(node, ...)
    print(node.type,...)
    local t = node.type
    if t == SELECTOR then

        for i=1, #node do
            if Traverse(node[i], ...) then
                return true
            end
        end
        return false
    elseif t == SEQUENCE then
        for i=1, #node do
            if not Traverse(node[i], ...) then
                return false
            end
        end
        return true
    elseif t == CONDITION then
        for i=1, #node do
            if not node[i](...) then
                return false
            end
        end
        return true
    elseif t == ACTION then
        for i=1, #node do
            node[i](...)
        end
        return true
    end
end

local root =
{
    type = SELECTOR,
    {
        type = SEQUENCE,
        {
            type = CONDITION,
            function(i,j)
                math.randomseed(os.time())
                local rand = math.random()
                print(rand)
                return rand > i
            end,
            function(i,j)
                math.randomseed(os.time())
                local rand = math.random()
                print(rand)
                return rand < j
            end,
        },
        {
            type = ACTION,
            function() print("random") end,
        },
    },
    {
        type = ACTION,
        function() print("idle") end,
    },
}

local input1 = 0.2
local input2 = 0.7
Traverse(root, input1, input2)

