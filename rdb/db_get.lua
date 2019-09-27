--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 12:30
-- To change this template use File | Settings | File Templates.

--[[
     --raw 中文格式 ;  --ldb 单步调试; 分隔符号 @

     ##维护 perm 数据；
     -- 参数params 格式:table is require, id is option
     -- 单条数据
        :> redis-cli  --raw --eval rdb/db_get.lua  table id , perms orgs
     -- 所有数据
        :> redis-cli  --raw --eval rdb/db_get.lua  table , perms
     -- 参数 json 格式; 参数不能有空格与逗号,必须双引号 todo urlencode urldecode
        :> redis-cli --raw --eval rdb/db_get.lua  json , {\"table\":\"perms\"\,\"id\":\"orgs\"}

     -- 固化插入脚本到 redis
        :> redis-cli --raw script load "$(cat rdb/db_get.lua)"
        :>>> 8ca91f9f3fe16a5e4808ec7c343d06e3a59d921f
        redis-cli --raw hset dbscript get 8ca91f9f3fe16a5e4808ec7c343d06e3a59d921f
        redis-cli --raw hget dbscript get
        :>>>

     -- 测试插入脚本 for redis
        :>redis-cli --raw evalsha 8ca91f9f3fe16a5e4808ec7c343d06e3a59d921f 2 table perms
        :>redis-cli --raw evalsha 8ca91f9f3fe16a5e4808ec7c343d06e3a59d921f 2 table id perms orgs
        :>redis-cli --raw evalsha 8ca91f9f3fe16a5e4808ec7c343d06e3a59d921f 1 json {\"table\":\"perms\"}
        :>redis-cli --raw evalsha 8ca91f9f3fe16a5e4808ec7c343d06e3a59d921f 1 json {\"table\":\"perms\"\,\"id\":\"orgs\"}

     --测试
     --     数据：
     --       redis-cli  --raw  hgetall systb_perms
     --     记录总数：
     --       redis-cli  --raw  hgetall systbs
--]]

-- ##维护 perm 数据；

-- 返回数据：
--    {"data":[{"table":"perms"            },{"orgs":{"name":"组织","table":"systb_perms","id":"orgs","res":"user\/orgs","desc":"组织机构"}}],"msg":"数据获取成功"}
--    {"data":[{"id":"orgs","table":"perms"},{"orgs":{"name":"组织","table":"systb_perms","id":"orgs","res":"user\/orgs","desc":"组织机构"}}],"msg":"数据获取成功"}


redis.log(redis.LOG_DEBUG,'get db data......')

--------------------------------常用函数-begin -------------------------

local sfind = string.find

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


local function arrval2kv(arr)
    local kv = {}
    for k, v in pairs(arr) do
        kv[v] = true
    end
    return kv
end

-- 参数KEYS/ARGV转化为 kv
local function arr2kv(key,val)
    local result = {}
    for i=1, #key,1 do
        result[key[i]] = val[i]
    end
    return result;
end

local function arrkv2kv(keyval)
    local result = {}
    for i = 1, #keyval, 2 do
        local k = keyval[i]
        local v = keyval[i+1]
        result[k] = v
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

-- 返回数据
local function msg(msg,err,data)

    local info = {}
    info.msg = msg;
    info.data = data;

    local result = {}
    if(err)
    then
        info.status = 400
        result.err = cjson.encode(info);

    else
        info.status = 200
        result.ok = cjson.encode(info);
    end

    redis.debug(result)
    redis.log(redis.LOG_DEBUG,result)

    return result;
end


--#获取单条记录
-- table:string
-- idval:string
-- fields:table
local function redis2rdb4one(table,idval)
    --        获取单条记录
    local flds = redis.call('hscan',table,0,'match',idval..'@'..'*')[2];

    -- 单条数据获取
    local result = {}
    result.table = table
    result.id = idval

    for i = 1, #flds, 2 do
        local k = string.sub(flds[i],#idval+2,#flds[i])

--        local k = flds[i]
        local v = flds[i+1]
        --      #数据解压json_支持
        if(k == 'text' or k == 'desc' or k == 'content' or string.match(k, "^json_"))
        then
            v = cmsgpack.unpack(v)
        end

--        -- 提取指定字段
--        if (fields) then
--            redis.log(redis.LOG_DEBUG,'提取指定字段',k,fields)
--
--            if (fields[k])  then
--                result[k] = v
--            end
--        else --提取所有字段

--            redis.log(redis.LOG_DEBUG,'提取所有字段',k,fields)

            result[k] = v
--        end

    end

    return result;
end


--#获取单条记录
-- table:string
-- idval:string
-- fields:table
--local function redis2rdb4onefields(table,idval,fields)
--    --        获取单条记录
----    local flds = redis.call('hscan',table,0,'match',idval..'@'..'*')[2];
--
--    -- 单条数据获取
--    local result = {}
--    result.table = table
--    result.id = idval
--
--    for i = 1, fields, 2 do
--        local k = string.sub(flds[i],#idval+2,#flds[i])
--
--        --        local k = flds[i]
--        local v = flds[i+1]
--        --      #数据解压json_支持
--        if(k == 'text' or k == 'desc' or k == 'content' or string.match(k, "^json_"))
--        then
--            v = cmsgpack.unpack(v)
--        end
--
--        -- 提取指定字段
--        if (fields) then
--            redis.log(redis.LOG_DEBUG,'提取指定字段',k,fields)
--
--            if (fields[k])  then
--                result[k] = v
--            end
--        else --提取所有字段
--
--            redis.log(redis.LOG_DEBUG,'提取所有字段',k,fields)
--
--            result[k] = v
--        end
--
--    end
--
--    return result;
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

--        print('table get',key,' params:' ,tbl ,idval)
        local fld_vals = redis.call('hget',tbl,idval..'@'..key);
        redis.log(redis.LOG_DEBUG,'获取数据-关联字段:',key,fld_vals)
        local tblfldvals = split(fld_vals, ',');
        redis.log(redis.LOG_DEBUG,'多记录数据:',cjson.encode(tblfldvals))

--        tbl = key
--        idval = key..'_get_val'
        tbl = 'systb'..'_'..string.gsub(key,":","",1);

        local n = {}
        result[key]= n

        for k, v in pairs(tblfldvals) do
            local obj = {}
            print('v....',v,cjson.encode(node))
            Traverse(DeepCopy(node), tbl, v, obj)

            n[v] = obj
        end

--        if (key ==':roles') then --节点复制
--            for k, v in pairs({'user','admin'}) do
--                print('v....',v,cjson.encode(node))
--                Traverse(DeepCopy(node), tbl, v, obj)
--
--                n[v] = obj
--            end
--        end
--
--        if (key ==':perms') then --节点复制
--            for k, v in pairs({'db','uri'}) do
--                print('v....',v,cjson.encode(node))
--                Traverse(DeepCopy(node), tbl, v, obj)
--
--                n[v] = obj
--            end
--        end

        node = nil --节点已分拆，清除；fixme 多字段关联


    elseif find(key,",") then  --节点字段处理
        local tblfld = split(key, ',');
        Traverse(tblfld, tbl, idval, result)

    elseif key =='id' then

--        print('field',key,' params:' ,tbl, idval)
        redis.log(redis.LOG_DEBUG,'获取数据id:',key,idval)
        result['id'] = idval

    else

--        print('field get',key,' params:' ,tbl, idval)
--        result[key] = {tbl..idval}

        local fld_vals = redis.call('hget',tbl,idval..'@'..key);
        redis.log(redis.LOG_DEBUG,'获取数据:',key,fld_vals)
        result[key] = fld_vals

    end

    Traverse(node, tbl, idval, result)

end
--
----递归解析关联fields,本质上是一棵树：id|name|:roles>:perms>id,name,res'
--local recu_fields
--function recu_fields(fld_table,fld_table_id,fields_queue,result)
--    if #fields_queue == 0 or fields_queue == nil then
--        return
--    end
--
--    redis.log(redis.LOG_DEBUG,'开始数据:',fld_table,fld_table_id,cjson.encode(fields_queue),cjson.encode(result))
--
--
--    --消费 keys 队列数据，获取 key,获取 val
--    local fld_key = table.remove(fields_queue,1)
--    if fld_key=='id' then --特殊字段处理
--        result['id'] = fld_table_id
--    else
--
--        if start_with(fld_key,":") then  --节点数据处理
--            redis.log(redis.LOG_DEBUG,'节点数据:',fld_key)
--
--            --关联字段队列
--            local s, e = string.find(fld_key, ":", 2)
--            if s ~= nil then
--                local tblfld = split(fld_key, '>');
--                recu_fields(fld_table,fld_table_id,tblfld,result)
--            else
--
--                local obj = {}
--
--                redis.log(redis.LOG_DEBUG,'节点数据1:',fld_key,string.find(fld_key, ","))
--
--
--                result[fld_key] = obj --节点数据
--
--                local fld_vals = redis.call('hget',fld_table,fld_table_id..'@'..fld_key);
--                redis.log(redis.LOG_DEBUG,'获取数据:',fld_key,fld_vals)
--
--                --多记录处理
--                local tblfldvals = split(fld_vals, ',');
--
--                redis.log(redis.LOG_DEBUG,'多记录数据:',cjson.encode(tblfldvals))
--
--                fld_table = 'systb'..'_'..string.gsub(fld_key,":","",1);
--                redis.log(redis.LOG_DEBUG,'获取数据表:',fld_table)
--
--                for k, v in pairs(tblfldvals) do
--                    fld_table_id = v
--                    recu_fields(fld_table,fld_table_id,fields_queue,obj)
--                end
--
--            end
--
--
--
--
--        else
--
--            redis.log(redis.LOG_DEBUG,'字段:',fld_key)
--
--            if string.find(fld_key, ",") then
--
--                local tblfld = split(fld_key, ',');
--                redis.log(redis.LOG_DEBUG,'关联字段:',cjson.encode(tblfld))
--
--                local obj = {}
--
--                --                fld_table = 'systb'..'_'..string.gsub(fld_key,":","",1);
--                recu_fields(fld_table,fld_table_id,tblfld,obj)
--
--                result[fld_key] = obj --节点数据
--
--            else
--
--
--                local fld_vals = redis.call('hget',fld_table,fld_table_id..'@'..fld_key);
--                redis.log(redis.LOG_DEBUG,'获取数据:',fld_key,fld_vals)
--                result[fld_key] = fld_vals --叶子数据
--
--            end
--
--
--
--        end
--
--    end
--
--    --递归完成同级数据处理
--    recu_fields(fld_table,fld_table_id,fields_queue,result)
--
--
--end



--[[
--redis2rdb  从redis获取数据
--参数：table;获取所有数据
--参数：table-idvalue;获取一条数据
--]]
local function redis2rdb(argkv)

    --[[
    一个 hash 一个数据表：有利于数据优化存储，技术支持hscan。 hscan,hset,hmget
        所有记录集合[sys_table; hscan id*]：id_idval1...id_idvaln;idval1_cnt...idvaln_cnt, --- id 值/字段数
        一条记录集合[table; hscan idval* ;hmget fields]：idval_field1key...idval_fieldnkey； ----fieldkey/fieldval
        k压缩数据处理[cmspack.pack cmspack.unpac]：text content json_ desc 保存时候压缩/获取时解压
        关联数据处理[rfld@table@fld]：关联字段标志/关联表table名称/关联field字段名称 值为fieldval列表
    ]]--
    -- 通用存储，保存所有的 key/value 数据，主键：id-idvale/field-count; filed=k ,value =v
    local tables = 'systbs';
    local table = 'systb'..'_'..argkv['table']

    local result = {}
    local idval = argkv['id']
    local fields = argkv['fields']


    if (idval) then

        local recid = 'id'..'@'..idval
        if (redis.call('hexists',table,recid)==1) then
            redis.log(redis.LOG_DEBUG,'提取指定记录:',table,recid)

            --            如果制定了数据列以及关联数据列
--                'id|name|:roles—>:perms->id,name,res'  roles,perms 既是表名也是字段名
--            redis-cli  --raw --eval rdb/db_get.lua  table id fields , users jamesmo 'id|name|:roles>:perms>id,name,res'
--              不用解析引擎就得用一堆 for 实现解析
            if (fields) then
                redis.log(redis.LOG_DEBUG,'提取指定字段:',fields)

                --获取返回的数据字段名称
                local fieldlist = split(fields, "|");

                result[idval] =  Traverse(fieldlist,table,idval,result)
--                Traverse(split(fields,"|"),'users','user', result)

--                for i = 1, #fieldlist do

--                    redis.log(redis.LOG_DEBUG,'提取字段:',fieldlist[i])

--                    recu_fields(table,idval,fieldlist,result)

--                    if start_with(fieldlist[i],":") then
--                        redis.log(redis.LOG_DEBUG,'提取关联字段:',fieldlist[i])
--
--                        local tblfld = split(fieldlist[i], '>');
--                        redis.log(redis.LOG_DEBUG,'关联字段:',cjson.encode(tblfld))
--
--                        local fld_table=table;
--                        local fld_table_id=idval;
--
--                        for j = 1, #tblfld do
--                            if start_with(tblfld[j],":") then
--                                redis.log(redis.LOG_DEBUG,'既是关联字段名称，也是关联表名称',tblfld[j-1],tblfld[j])
--
--                                --users->roles的值,是 roles 的 idval
--                                fld_table_id = redis.call('hget',fld_table,fld_table_id..'@'..tblfld[j]);
--                                redis.log(redis.LOG_DEBUG,'既是关联字段值，也是关联表idval',fld_table_id,tblfld[j])
--
--                                --roled->perms的值
--                                fld_table = 'systb'..'_'..tblfld[j]
--
--
--                            else
--                                redis.log(redis.LOG_DEBUG,'关联表-关联字段主键值',fld_table,fld_table_id)
--
--                                local flds = split(tblfld[j], ',');
--                                for k = 1, #flds do
--                                    local fieldval = redis.call('hget',fld_table,fld_table_id..'@'..flds[k]);
--
--                                    redis.log(redis.LOG_DEBUG,'关联表-关联字段',fld_table,flds[k],fieldval)
--
----                                    result[fieldlist[i]] = fieldval;
--
--                                end
--                            end
--
--                        end
--
--                    else
--                        redis.log(redis.LOG_DEBUG,'提取非关联字段',fieldlist[i])
--
--                        local fieldval = redis.call('hget',table,idval..'@'..fieldlist[i]);
--                        result[fieldlist[i]] = fieldval;
--
--                    end
--                end

            else

                redis.log(redis.LOG_DEBUG,'提取所有字段')

                result[idval] = redis2rdb4one(table,idval)

            end



        else
            return msg('数据不存在',true,{argkv});
        end


    else
        redis.log(redis.LOG_DEBUG,'提取所有记录',table)

        local ids = redis.call('hscan',table,0,'match','id@'..'*')[2];
        for i = 1, #ids, 2 do
            local k = string.sub(ids[i],4,#ids[i]) --字段名称
--            local k = ids[i]
--            local v = ids[i+1] --字段数
            result[k] = redis2rdb4one(table, k)
        end

    end

    return msg('数据获取成功',false,{argkv,result});
end


--------------------------------常用函数-end -------------------------



--------------------------------参数合规检查-begin -------------------------

-- 参数转换
local argkv = arr2kv(KEYS,ARGV)

--if 参数是 json 进行加工

if(argkv['json'] ~= nil)
then
    --    redis.debug(argkv['json'])
    argkv = cjson.decode(argkv['json'])
end



--参数合规判定处理 json 参数只有 1 个
--参数必须：table id;key/value 成对出现。
if(#KEYS<1 or #ARGV<1 or (#KEYS - #ARGV ~= 0))
then
    local errmsg = "参数不匹配：redis-cli --ldb --eval lua/db_get.lua  table [id] , tablevalue [idvalue]"
    return msg(errmsg,true,{KEYS,ARGV})
end

--if(argkv['id'] == nil or argkv['table'] == nil )
if( argkv['table'] == nil )
then
    local errmsg = "id or table 参数不匹配：redis-cli --ldb --eval rdb/db_get.lua  table id , tablevalue idvalue"
    return msg(errmsg,true,argkv)
end

--------------------------------参数合规检查-end -------------------------



--------------------------------构建数据并且存储-begin -------------------------
redis.debug(argkv['table'])
redis.debug(argkv['id'])

return redis2rdb(argkv)



--------------------------------构建数据并且存储-end -------------------------


--return msg('数据获取成功',false,argkv);