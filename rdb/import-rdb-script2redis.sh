. rdb/log.sh


log info 将模拟关系数据库脚本导入到redis

###将模拟关系数据库脚本导入到 redis

log warn 清空数据库
redis-cli flushall 2>&1 1>/dev/null

##Linux有三个标准IO，stdin,stdout,stderr，对应的文件描述符是0,1,2.
##2>&1的意思就是将标准错误重定向到标准输入上
##stdin/stdout都重定向到一个/dev/null的设备文件  2>&1 1>/dev/null

#加载lua脚本到 redis，生成 sha 函数串
sha_ins=$(redis-cli --raw script load "$(cat rdb/db_insert.lua)" )
sha_get=$(redis-cli --raw script load "$(cat rdb/db_get.lua)" )
sha_del=$(redis-cli --raw script load "$(cat rdb/db_delete.lua)")


log debug rdb/db_insert_data.lua,${sha_ins}
log debug db_get_data.lua,${sha_get}
log debug db_get_data.lua,${sha_del}

#保存 sha 函数串到 dbscript ,便于检索
redis-cli --raw hset dbscript insert ${sha_ins}  2>&1 1>/dev/null
redis-cli --raw hset dbscript get ${sha_get}  2>&1 1>/dev/null
redis-cli --raw hset dbscript delete ${sha_del}  2>&1 1>/dev/null

redis-cli save 2>&1 1>/dev/null

dbscript=$(redis-cli --raw hgetall dbscript)


log debug $(echo ${dbscript}|sed 's/ /|/g')
#log debug ${dbscript}

log debug "测试数据 perms orgs"

redis-cli --raw evalsha ${sha_ins}   6 table  id name desc res json_abc  perms orgs 组织 组织机构 user/orgs jsonABC
redis-cli --raw evalsha ${sha_ins}   6 table  id name desc res json_abc  perms orgs 组织 组织机构 user/orgs jsonABC

redis-cli --raw evalsha ${sha_get} 2 table id perms orgs
redis-cli --raw evalsha ${sha_del} 2 table id perms orgs

redis-cli --raw evalsha ${sha_get} 2 table id perms orgs
redis-cli --raw evalsha ${sha_del} 2 table id perms orgs
