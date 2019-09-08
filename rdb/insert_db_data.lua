--
-- Created by IntelliJ IDEA.
-- User: moyong
-- Date: 2019/8/13
-- Time: 12:30
-- To change this template use File | Settings | File Templates.
--[[
将Lua脚本加载到Redis服务端，得到该脚本的sha1校验和，evalsha命令使用sha1作为参数可以直接执行对应的Lua脚本，
避免每次发送Lua脚本的开销。这样客户端就不需要每次执行脚本内容，而脚本也会常驻在服务端，脚本内容得到了复用。
加载脚本： script load命令可以将脚本内容加载到Redis内存中。
redis-cli script load “$(cat lua_get.lua)”
得到的sha1的值
“7413dc2440db1fea0a0dbefa68eefaf149c”
执行脚本
evalsha 脚本sha1值 key个数 key列表 参数列表
调用lua_get.lua脚本
eval 7413dc2440db1fea0a0dbefa68eefaf149c 1 redis world


redis.LOG_DEBUG
redis.LOG_VERBOSE
redis.LOG_NOTICE
redis.LOG_WARNING

]]
--[[
     ##维护 perm 数据；:id,name is reqquire
     --raw 中文格式 ;分隔符号 @
        redis-cli --raw --ldb --eval rdb/insert_db_data.lua  table  id name desc res json_abc , perms orgs 组织 组织机构 user/orgs jsonABC

     --- json 格式参数;参数不能有空格与逗号,必须双引号
        redis-cli --raw --eval rdb/insert_db_data.lua  json , \
        {\"table\":\"perms\"\,\"id\":\"orgs\"\,\"name\":\"组织\"\,\"desc\":\"组织机构\"\,\"res\":\"user/orgs\"\,\"json_abc\":\"jsonABC\"}

    redis-cli --raw script load "$(cat rdb/insert_db_data.lua)"
    :> f9f05a7068b9cb5eecbf2a9fa2cca52f8dc14d7b
    :>
    redis-cli --raw evalsha f9f05a7068b9cb5eecbf2a9fa2cca52f8dc14d7b   6 table  id name desc res json_abc  perms orgs 组织 组织机构 user/orgs jsonABC

    redis-cli --raw evalsha f9f05a7068b9cb5eecbf2a9fa2cca52f8dc14d7b 1 json \
    {\"table\":\"perms\"\,\"id\":\"orgs\"\,\"name\":\"组织\"\,\"desc\":\"组织机构\"\,\"res\":\"user/orgs\"\,\"json_abc\":\"jsonABC\"}
     --测试
     --     数据：hgetall systb_perms/记录总数：hgetall systbs
--]]

redis.log(redis.LOG_NOTICE,'insert db data......')

--执行了redis.replicate_commands()之后，Redis就开始使用multi/exec来包围Lua脚本中调用的命令，持久化和复制的只是脚本中redis命令而
--不是整个Lua脚本，那么AOF文件和备库中拿到的就是一个确定的结果。
--redis.replicate_commands()可以和redis.set_repl()配合，来控制写命令是否进行持久化和主从复制：
--redis.set_repl(redis.REPL_ALL) -- 既持久化也主从复制。
--redis.set_repl(redis.REPL_AOF) -- 只持久化不主从复制。
--redis.set_repl(redis.REPL_SLAVE) -- 只主从复制不持久化。
--redis.set_repl(redis.REPL_NONE) -- 既不持久化也不主从复制。
--默认REPL_ALL，当设置为其他模式时会有数据不一致的风险，所以不建议使用redis.set_repl()，使用redis.replicate_commands()来进行随机写入足矣。
redis.replicate_commands()

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

-- 返回数据
local function msg(msg,iserror,data)

    local info = {}
    info.msg = msg;
    info.data = data;

    local result = {}
    if(iserror)
    then
        result.err = cjson.encode(info); --按 redis 的协议返回错误信息

    else
        result.ok = cjson.encode(info);  --按 redis 的协议返回成功信息
    end

    redis.log(redis.LOG_DEBUG,cjson.encode(result))

    return result

end

--异常处理函数 status = xpcall( myfunction, myerrorhandler )
local function myerrorhandler( err )
    redis.log(redis.LOG_WARNING,'erro info ......')
    redis.log(redis.LOG_WARNING,err.code)
    redis.log(redis.LOG_WARNING,err)
    --    redis.log(redis.LOG_WARNING,debug.traceback()) --redis 环境不能正确返回错误信息
end

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
    local recid = 'id'..'@'..idval


    -- 单条数据存储
    for k, v in pairs(argkv) do
        if( k ~= 'id' and k ~= 'table')
        then
--            redis.debug(k)
--            redis.debug( k ~= 'table')
            -- 大块文本数据压缩存储cmsgpack
            -- 打包压缩存储，节约空间，
            --local packval = cmsgpack.pack(argkv)
            --local packsou = cmsgpack.unpack(packval)

            if(k == 'text' or k == 'desc' or k == 'content' or string.match(k, "^json_") )
            then
                redis.call('hset', table, idval..'@'..k, cmsgpack.pack(v));
            else
                redis.call('hset', table, idval..'@'..k, v);
            end
            --todo 关联数据处理[rfld@table@fld]：暂时不用直接存储列表；获取数据的时候，加载关联数据
        end
    end

--    记录主键及字段数: key = table, pattern = idval-* (-避免前缀相同的字段)
    local flds = redis.call('hscan',table,0,'match',idval..'@'..'*');
    redis.call('hset', table, recid, #flds[2]/2);

    -- 数据表信息保存：数据条数
    local recCnt = redis.call('hscan',table,0,'match','id@'..'*');
    redis.call('hset',tables, table,#recCnt[2]/2);

    return msg('数据插入成功',false,argkv);
--    return 'ok'
end


--------------------------------常用函数-end -------------------------



--------------------------------参数合规检查-begin -------------------------
-- 归属转换
local argkv = arr2kv(KEYS,ARGV)


--if 参数是 json 进行加工

if(argkv['json'] ~= nil)
then
--    redis.debug(argkv['json'])
    redis.log(redis.LOG_DEBUG,argkv['json'])

    argkv = cjson.decode(argkv['json'])

end


--参数合规判定处理 json 参数只有 1 个
--参数必须：table id;key/value 成对出现。
--if(#KEYS<2 or #ARGV<2 or (#KEYS - #ARGV ~= 0))
if((#KEYS - #ARGV ~= 0))
then
    local errmsg = "参数不匹配：redis-cli --ldb --eval lua/insert_db_data.lua  table id name ... , tablevalue idvalue namevalue ......"
    return msg(errmsg,true,{KEYS,ARGV})
end


if(argkv['id'] == nil or argkv['table'] == nil )
then
    local errmsg = "id or table 参数不匹配：redis-cli --ldb --eval lua/insert_db_data.lua  table id name ... , tablevalue idvalue namevalue ......"
    return msg(errmsg,true,argkv)
end

--------------------------------参数合规检查-end -------------------------



--------------------------------构建数据并且存储-begin -------------------------
return rdb2redis(argkv)

--local status, err = pcall(rdb2redis(argkv))
--返回异常信息到 redis
--if (not status) then
--    redis.log(redis.LOG_DEBUG, err)
--end

-- 带参数的 function 有 bug
--local status = xpcall( rdb2redis(argkv), myerrorhandler )
--redis.log(redis.LOG_DEBUG, msg)
--return msg;

--------------------------------构建数据并且存储-end -------------------------


--return msg('数据插入成功',false,argkv);


