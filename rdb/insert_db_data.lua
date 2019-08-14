--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 12:30
-- To change this template use File | Settings | File Templates.

--[[
     ##维护 perm 数据；:id,name is reqquire
     --raw 中文格式
        redis-cli --raw --ldb --eval lua/insert_db_data.lua  table   id name desc res , perm orgs 组织 组织机构 user/orgs
--]]

redis.log(redis.LOG_DEBUG,'insert db data......')


--------------------------------常用函数-begin -------------------------
-- 数组值转化为字典
local function arr2kv(arr)
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
--rdb2redis 存储数据到 redis

local function rdb2redis(argkv)

    --- dbs sys_dbs
    --- tables sys_table
    --- records sys_table_idkey
    --- fiels key

    -- 通用存储，保存所有的 key/value 数据，table-id 为 key ; filed=k ,value =v
    local tables = 'sys_tbs';
    local table = 'sys'..'_'..argkv['table']
    local recid = table..'-'..argkv['id']

    -- 单条数据存储
    for k, v in pairs(argkv) do
        if( k ~= 'id' or k ~= 'table')
        then
            -- 大块文本数据压缩存储cmsgpack
            -- 打包压缩存储，节约空间，
            --local packval = cmsgpack.pack(argkv)
            --local packsou = cmsgpack.unpack(packval)

            if(k == 'text' or k == 'desc' or k == 'content')
            then
                redis.call('hset', recid, k, cmsgpack.pack(v));
            else
                redis.call('hset', recid, k, v);
            end
        end
    end

    -- 单条记录信息保存：字段数量
    local fieldCnt = redis.call('hlen',recid);
    redis.call('hset',table, recid,fieldCnt);


    -- 更新表信息：数据条数
    local searchRec = redis.call('scan',0,'match',table..'*');
    redis.debug(searchRec)
    local cnt = #searchRec[2]-1

    redis.call('hset',tables,table,cnt);


    return msg('数据插入成功',false,argkv);
end


--------------------------------常用函数-end -------------------------



--------------------------------参数合规检查-begin -------------------------


--参数合规判定处理
--参数必须：table id;key/value 成对出现。
if(#KEYS<2 or #ARGV<2 or (#KEYS - #ARGV ~= 0))
then
    local errmsg = "参数不匹配：redis-cli --ldb --eval lua/insert_db_data.lua  table id name ... , tablevalue idvalue namevalue ......"
    return msg(errmsg,true,{KEYS,ARGV})
end

-- 归属转换
local argkv = arr2kv(KEYS,ARGV)

if(argkv['id'] == nil or argkv['table'] == nil )
then
    local errmsg = "id or table 参数不匹配：redis-cli --ldb --eval lua/insert_db_data.lua  table id name ... , tablevalue idvalue namevalue ......"
    return msg(errmsg,true,argkv)
end

--------------------------------参数合规检查-end -------------------------



--------------------------------构建数据并且存储-begin -------------------------
--rdb2redis(argkv)

local status = xpcall( rdb2redis(argkv), myerrorhandler )


--------------------------------构建数据并且存储-end -------------------------


return msg('数据插入成功',false,argkv);


