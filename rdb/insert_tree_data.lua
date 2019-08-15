--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 12:30
-- To change this template use File | Settings | File Templates.

--[[
--  tree
--  树的构建，增加，删除
--  一次性获取所有的子节点
--  node k/v  child/parent
--  key     root
--          root@1level
--          root@1level@2level
--          root@1level
--          root@1level@2level
--          root@1level@2level@3level
--  value (parent id name)

     ##维护 perm 数据；:id,name is reqquire
     --raw 中文格式 ;分隔符号 @
     --  北京-》北京市->西城区
        redis-cli --raw --ldb --eval rdb/insert_tree_data.lua  tree  id name parentid , orgtree beijing 北京 root
        redis-cli --raw --ldb --eval rdb/insert_tree_data.lua  tree  id name parentid , orgtree bjcity 北京市 root@beijing
        redis-cli --raw --ldb --eval rdb/insert_tree_data.lua  tree  id name parentid , orgtree xcq 西城区 root@beijing@bjcity
        redis-cli --raw --ldb --eval rdb/insert_tree_data.lua  tree  id name parentid , orgtree hdq 海淀区 root@beijing@bjcity
     --测试
     --     获取树形数据：hscan systree_city 0 match root*
--]]

redis.log(redis.LOG_DEBUG, 'insert db data......')
-------------------------------- 常用函数-begin -------------------------
-- 数组值转化为字典
local function arrval2kv(arr)
    local kv = {}
    for k, v in pairs(arr) do
        kv[v] = true
    end
    return kv
end

-- 参数KEYS/ARGV转化为 kv
local function arr2kv(key, val)
    local result = {}
    for i = 1, #key, 1 do
        result[key[i]] = val[i]
    end
    return result;
end

-- 返回数据
local function msg(msg, err, data)

    local info = {}
    info.msg = msg;
    info.data = data;

    local result = {}
    if (err) then
        result.err = cjson.encode(info);

    else
        result.ok = cjson.encode(info);
    end

    redis.debug(result)
    redis.log(redis.LOG_DEBUG, result)

    return result;
end

-- 返回异常信息
local function myerrorhandler(err)

    --    return msg(err,true,{debug.debug,debug.traceback()})
    return msg(err, true, debug)
end

-- 调用扑捉异常
--local function myfunction ()
--    n = n/nil
--end

--local status = xpcall( myfunction, myerrorhandler )

--return status



--rdb2redis 存储数据到 redis
local function rdb2redis(argkv)
    --[[
    一个 hash 一个tree表：有利于数据优化存储，技术支持hscan,hset
        子树[sys_tree; hscan systree 0 match idvalue@*]
        单节点[tree-node; hget systree 0 match idkey

        id parent key=parent@id name
    ]] --

    -- 通用存储，保存所有的 key/value 数据，主键：id-idvale/field-count; filed=k ,value =v
    local trees = 'systrees';
    local tree = 'systr' .. '_' .. argkv['tree']
    local idval = argkv['id']
    local pidval = argkv['parentid']
    local key = pidval .. '@' .. idval

    -- 单节点存储
    local obj = {}
    for k, v in pairs(argkv) do
        if (k ~= 'tree') then
            redis.debug(k)
            obj[k] = v
        end
    end
    --编码为字符串，获取数据的时候解码
    --    redis.call('hset', tree, key, obj);
    local o = cjson.encode(obj)
    redis.call('hset', tree, key, o);

    --子节点数量,随时变化在终端动态计算
    --    local flds = redis.call('hscan',table,0,'match',key..'*');
    --    redis.call('hset', table, key, #flds[2]/2);

    -- 树的节点数量
    local recCnt = redis.call('hlen', tree);
    redis.call('hset', trees, tree, recCnt);

    return msg('数据插入成功', false, { argkv, obj });
end


-------------------------------- 常用函数-end -------------------------



-------------------------------- 参数合规检查-begin -------------------------


--参数合规判定处理
--参数必须：tree pid id; key/value 成对出现。
if (#KEYS < 3 or #ARGV < 3 or (#KEYS - #ARGV ~= 0)) then
    local errmsg = "参数不匹配：redis-cli --ldb --eval rdb/insert_tree_data.lua  tree id parentid name ... , tablevalue idvalue parentvalue namevalue ......"
    return msg(errmsg, true, { KEYS, ARGV })
end

-- 归属转换
local argkv = arr2kv(KEYS, ARGV)

if (argkv['id'] == nil or argkv['tree'] == nil or argkv['parentid'] == nil) then
    local errmsg = "id or parentid or tree 参数不匹配：redis-cli --ldb --eval rdb/insert_tree_data.lua  tree id parentid name ... , tablevalue idvalue parentvalue namevalue ......"
    return msg(errmsg, true, argkv)
end

-------------------------------- 参数合规检查-end -------------------------



-------------------------------- 构建数据并且存储-begin -------------------------
return rdb2redis(argkv)

--local status = xpcall( rdb2redis(argkv), myerrorhandler )


-------------------------------- 构建数据并且存储-end -------------------------


--return msg('数据插入成功',false,argkv);


