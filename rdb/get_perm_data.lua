--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 12:30
-- To change this template use File | Settings | File Templates.
-- ##维护 perm 数据；
-- redis-cli --raw --ldb --eval rdb/get_perm_data.lua  table id , perms orgs
-- 返回数据：
--    {"data":[{"table":"perms"            },{"orgs":{"name":"组织","table":"systb_perms","id":"orgs","res":"user\/orgs","desc":"组织机构"}}],"msg":"数据获取成功"}
--    {"data":[{"id":"orgs","table":"perms"},{"orgs":{"name":"组织","table":"systb_perms","id":"orgs","res":"user\/orgs","desc":"组织机构"}}],"msg":"数据获取成功"}


redis.log(redis.LOG_DEBUG,'get db data......')

--------------------------------常用函数-begin -------------------------
-- 数组值转化为字典
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




-- 返回数据
local function msg(msg,err,data)

    local info = {}
    info.msg = msg;
    info.data = data;

    local result = {}
    if(err)
    then
        result.err = cjson.encode(info);

    else
        result.ok = cjson.encode(info);
    end

    redis.debug(result)
    redis.log(redis.LOG_DEBUG,result)

    return result;
end

-- 返回异常信息
local function myerrorhandler( err )

    --    return msg(err,true,{debug.debug,debug.traceback()})
    return msg(err,true,debug)
end

-- 调用扑捉异常
--local function myfunction ()
--    n = n/nil
--end

--local status = xpcall( myfunction, myerrorhandler )

--return status


--#获取单条记录
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
        result[k] = v
    end

    return result;
end

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
    if (idval) then

         result[idval] = redis2rdb4one(table,idval)

    else

        local ids = redis.call('hscan',table,0,'match','id@'..'*')[2];
        for i = 1, #ids, 2 do
            local k = string.sub(ids[i],4,#ids[i]) --字段名称
--            local k = ids[i]
--            local v = ids[i+1] --字段数
            result[k] = redis2rdb4one(table, k)
        end

    end




--    for k, v in pairs(argkv) do
--        if( k ~= 'id' or k ~= 'table')
--        then
--            -- 大块文本数据压缩存储cmsgpack
--            -- 打包压缩存储，节约空间，
--            --local packval = cmsgpack.pack(argkv)
--            --local packsou = cmsgpack.unpack(packval)
--
--            if(k == 'text' or k == 'desc' or k == 'content')
--            then
--                redis.call('hset', recid, k, cmsgpack.pack(v));
--            else
--                redis.call('hset', recid, k, v);
--            end
--        end
--    end

--    单条记录信息保存：字段数量
--    local fieldCnt = redis.call('hlen',recid);
--    redis.call('hset',table, recid,fieldCnt);


--    更新表信息：数据条数
--    local searchRec = redis.call('scan',0,'match',table..'*');
--    redis.debug(searchRec)
--    local cnt = #searchRec[2]-1
--
--    redis.call('hset',tables,table,cnt);

    return msg('数据获取成功',false,{argkv,result});
end


--------------------------------常用函数-end -------------------------



--------------------------------参数合规检查-begin -------------------------


--参数合规判定处理
--参数必须：table id;key/value 成对出现。
if(#KEYS<1 or #ARGV<1 or (#KEYS - #ARGV ~= 0))
then
    local errmsg = "参数不匹配：redis-cli --ldb --eval lua/insert_db_data.lua  table id name ... , tablevalue idvalue namevalue ......"
    return msg(errmsg,true,{KEYS,ARGV})
end

-- 归属转换
local argkv = arr2kv(KEYS,ARGV)

--if(argkv['id'] == nil or argkv['table'] == nil )
if( argkv['table'] == nil )
then
    local errmsg = "id or table 参数不匹配：redis-cli --ldb --eval lua/insert_db_data.lua  table id name ... , tablevalue idvalue namevalue ......"
    return msg(errmsg,true,argkv)
end

--------------------------------参数合规检查-end -------------------------



--------------------------------构建数据并且存储-begin -------------------------
redis.debug(argkv['table'])
redis.debug(argkv['id'])

return redis2rdb(argkv)

--local status = xpcall( redis2rdb(argkv), myerrorhandler )


--------------------------------构建数据并且存储-end -------------------------


--return msg('数据获取成功',false,argkv);