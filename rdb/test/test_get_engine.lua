--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/9/27
-- Time: 20:44
-- To change this template use File | Settings | File Templates.
-- get for fields 指令解析 'id|name|:roles>:perms>id,name,res'

local cjson = require('cjson')
local sfind = string.find


local function start_with(str, substr)
    if str == nil or substr == nil then
        return false
    end
    if sfind(str, substr) ~= 1 then
        return false
    else
        return true
    end
end


local function find(str, substr)
    if str == nil or substr == nil then
        return false
    end
    if sfind(str, substr)  then
        return true
    else
        return false
    end
end


local function split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local function DeepCopy( obj )
    local InTable = {};
    local function Func(obj)
        if type(obj) ~= "table" then   --判断表中是否有表
            return obj;
        end
        local NewTable = {};  --定义一个新表
        InTable[obj] = NewTable;  --若表中有表，则先把表给InTable，再用NewTable去接收内嵌的表
        for k,v in pairs(obj) do  --把旧表的key和Value赋给新表
            NewTable[Func(k)] = Func(v);
        end
        return setmetatable(NewTable, getmetatable(obj))--赋值元表
    end
    return Func(obj) --若表中有表，则把内嵌的表也复制了
end


-- 压缩关联字段 直接要最后一层的权限
local function nodetrim(node,node1name,node2name)
    local result = {}
    for k, v in pairs(node[node1name]) do
        print(k,cjson.encode(v))
        for k1, v1 in pairs(v[node2name]) do
            result[k1] = v1
        end
    end
    node[node1name]=nil
    node[node2name]=result
    return node;
end
--
--local function nodetrim_recu(node, queue, obj)  --fixme
----    local obj = {}
--
----    local queue = { ... }
--    if queue == nil or #queue == 0 or #obj>1 then
--        return obj
--    else
--
--        print('入口：', cjson.encode(queue),cjson.encode(node))
--
--        local key = table.remove(queue,1)
--
--        print(key,'data：', cjson.encode(node[key]))
--
--        for k, v in pairs(node[key]) do
--
--            if (queue == nil or #queue == 0)  then
--                print(key,k,cjson.encode(queue),cjson.encode(v))
--                obj[k] = v
--
--            else
--
--                nodetrim_recu(v,queue,obj)
--
--            end
--
--
--        end
--        --    node[node1name]=nil
--        --    node[node2name]=result
--        --    return node;
--        return obj
--
--    end
--
--end



--    'id|name|:roles>:perms>id,name,res' get引擎-行为递归
local function Traverse(node, tbl, idval, result)
    if node == nil or #node == 0 then
        return
    end

    print('入口：', cjson.encode(node), tbl, idval)

    local key = table.remove(node,1)


--    for k, v in pairs(node) do

--        if sfind(key, ":", 2)  then  -- 分解数据
        if sfind(key, ">")  then  -- 分解数据

                local tblfld = split(key, '>');
            Traverse(tblfld, tbl, idval, result)

            --此处合并数据 todo 多层数据需递归处理


        elseif  start_with(key,":") then  --节点数据处理

            print('table get',key,' params:' ,tbl ,idval)

            tbl = key
--            idval = key..'_get_val'

            local n = {}
            result[key]= n

--            local obj1 = {}
--            local obj2 = {}
            if (key ==':roles') then --节点复制
                for k, v in pairs({'user','admin'}) do
                    local obj = {}

                    print('v....',v,cjson.encode(node))
                    Traverse(DeepCopy(node), tbl, v, obj)

                    n[v] = obj
                end
            end


            if (key ==':perms' and idval == 'user') then --节点复制

                for k, v in pairs({'uri'}) do
                    local obj = {}

                    print('v....uri :',v,cjson.encode(node))
                    Traverse(DeepCopy(node), tbl, v, obj)

                    n[v] = obj

--                    print('user......',v,cjson.encode(n))

                end

            end

            if (key ==':perms' and idval == 'admin') then --节点复制
                for k, v in pairs({'db','uri'}) do
                    local obj = {}

                    print('v....db uri :',v,cjson.encode(node))
                    Traverse(DeepCopy(node), tbl, v, obj)

                    n[v] = obj

--                    print('admin......',v,cjson.encode(n))

                end
            end

            print('return data...',key, tbl, idval, cjson.encode(n))

            node = nil --节点已分拆，清除；fixme 多字段关联


        elseif find(key,",") then  --节点字段处理
            local tblfld = split(key, ',');
            Traverse(tblfld, tbl, idval, result)

        elseif v =='id' then

            print('field',key,' params:' ,tbl, idval)

            result['id'] = idval

        else

            print('field get',key,' params:' ,tbl, idval)

            result[key] = {tbl..idval}

        end

    return Traverse(node, tbl, idval, result)

end


--只允许单字段关联
--local fields =  'id|name|:roles>:perms>id,name,res|:roles>id,name'
local fields =  'id|name|:roles>:perms>id,name,res'

local result = {}
Traverse(split(fields,"|"),'users','user', result)
print(cjson.encode(result))


local perms = nodetrim(DeepCopy(result),':roles',":perms")
print(cjson.encode(perms))

print('recu ......')
--perms = nodetrim_recu(DeepCopy(result),{':roles',":perms"}, {})
--print(cjson.encode(perms))
