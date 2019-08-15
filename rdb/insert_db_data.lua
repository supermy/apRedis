--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 12:30
-- To change this template use File | Settings | File Templates.

--[[
     ##维护 perm 数据；:id,name is reqquire
     --raw 中文格式
        redis-cli --raw --ldb --eval rdb/insert_db_data.lua  table  id name desc res json_abc , perms orgs 组织 组织机构 user/orgs jsonABC
     --测试
     --     数据：hgetall systb_perms/记录总数：hgetall systbs
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
    local idval = argkv['id']
    local recid = 'id'..'-'..idval

    -- 单条数据存储
    for k, v in pairs(argkv) do
        if( k ~= 'id' and k ~= 'table')
        then
            redis.debug(k)
            redis.debug( k ~= 'table')
            -- 大块文本数据压缩存储cmsgpack
            -- 打包压缩存储，节约空间，
            --local packval = cmsgpack.pack(argkv)
            --local packsou = cmsgpack.unpack(packval)

            if(k == 'text' or k == 'desc' or k == 'content' or string.match(k, "^json_") )
            then
                redis.call('hset', table, idval..'-'..k, cmsgpack.pack(v));
            else
                redis.call('hset', table, idval..'-'..k, v);
            end
            --todo 关联数据处理[rfld@table@fld]：暂时不用直接存储列表；获取数据的时候，加载关联数据
        end
    end

--    记录主键及字段数: key = table, pattern = idval-* (-避免前缀相同的字段)
    local flds = redis.call('hscan',table,0,'match',idval..'-'..'*');
    redis.call('hset', table, recid, #flds[2]/2);

    -- 数据表信息保存：数据条数
    local recCnt = redis.call('hscan',table,0,'match','id-'..'*');
    redis.call('hset',tables, table,#recCnt[2]/2);

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
return rdb2redis(argkv)

--local status = xpcall( rdb2redis(argkv), myerrorhandler )


--------------------------------构建数据并且存储-end -------------------------


--return msg('数据插入成功',false,argkv);


