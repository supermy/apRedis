--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 12:30
-- To change this template use File | Settings | File Templates.

--[[
     --raw 中文格式 ;  --ldb 单步调试; 分隔符号 @

     ##维护 perm 数据；只允许单条记录删除
     -- 参数params 格式:table id is require
     -- 单条数据
        :> redis-cli  --raw --eval rdb/db_delete.lua  table id , perms orgs
     -- 参数 json 格式; 参数不能有空格与逗号,必须双引号 todo urlencode urldecode
        :> redis-cli --raw --eval rdb/db_delete.lua  json , {\"table\":\"perms\"\,\"id\":\"orgs\"}

     -- 固化插入脚本到 redis
        :> redis-cli --raw script load "$(cat rdb/db_delete.lua)"
        :>>> fac208a01e0374c71d9bdd429cd554bd55a36b93
        redis-cli --raw hset dbscript get fac208a01e0374c71d9bdd429cd554bd55a36b93
        redis-cli --raw hget dbscript get
        :>>>

     -- 测试插入脚本 for redis
        :>redis-cli --raw evalsha fac208a01e0374c71d9bdd429cd554bd55a36b93 2 table id perms orgs
        :>redis-cli --raw evalsha fac208a01e0374c71d9bdd429cd554bd55a36b93 1 json {\"table\":\"perms\"\,\"id\":\"orgs\"}

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


redis.log(redis.LOG_DEBUG,'delete db data......')

--------------------------------常用函数-begin -------------------------

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
local function redis2rdb4one(table,idval)
    local idkey = 'id@'..idval

    redis.log(redis.LOG_DEBUG,table,idkey)
    redis.log(redis.LOG_DEBUG,redis.call('hexists',table,idkey))

    if (redis.call('hexists',table,idkey)==1) then
        redis.log(redis.LOG_DEBUG,table,idkey,' exists')

        --获取单条记录
        local flds = redis.call('hscan',table,0,'match',idval..'@'..'*')[2];

        --删除字段值
        for i = 1, #flds, 2 do
--            local k = string.sub(flds[i],#idval+2,#flds[i])
--            if redis.call('hexists',table,flds[i]) then
                redis.call('hdel',table,flds[i])
--            end
        end

        --删除主键
        redis.call('hdel',table,idkey)

        return true
    else
        redis.log(redis.LOG_DEBUG,'idkey',idkey,'not exists')
        return false
    end

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

--    return  redis2rdb4one(table,idval):msg('数据删除成功',false,{argkv}),msg('数据不存在',true,{argkv});
    --三目运算
    return (redis2rdb4one(table,idval) and {msg('数据删除成功',false,{argkv})} or {msg('数据不存在',true,{argkv})})[1]
--    return msg('数据删除成功',false,{argkv});
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
    local errmsg = "参数不匹配：redis-cli --ldb --eval lua/db_delete.lua  table id , tablevalue idvalue"
    return msg(errmsg,true,{KEYS,ARGV})
end

if(argkv['id'] == nil or argkv['table'] == nil )
then
    local errmsg = "id or table 参数不匹配：redis-cli --ldb --eval rdb/db_delete.lua  table id , tablevalue idvalue "
    return msg(errmsg,true,argkv)
end

--------------------------------参数合规检查-end -------------------------



--------------------------------构建数据并且存储-begin -------------------------
redis.debug(argkv['table'])
redis.debug(argkv['id'])

return redis2rdb(argkv)



--------------------------------构建数据并且存储-end -------------------------


--return msg('数据获取成功',false,argkv);