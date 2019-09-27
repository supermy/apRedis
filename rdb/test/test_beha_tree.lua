--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/9/27
-- Time: 17:08
-- To change this template use File | Settings | File Templates.
--
local sel = 'seletor'
local seq = 'sequence'
local con = 'condition'
local act = 'action'

function traverse(node, ...)
    local t = node.nodeType
    -- print(node.comment)
    if t == con then
        return node.func(...)
    elseif t == act then
        node.func(...)
        return true
    elseif t == sel then
        for i=1, #node.arr do
            if traverse(node.arr[i], ...) then
                return true
            end
        end
        return false
    elseif t == seq then
        for i=1, #node.arr do
            if not traverse(node.arr[i], ...) then
                return false
            end
        end
        return true
    end

    return false
end


