. rdb/log.sh


log info 清理RBAC数据库

redis-cli --raw --eval  rdb/db_delete.lua table id , users jamesmo
redis-cli --raw --eval  rdb/db_delete.lua table id , roles user
redis-cli --raw --eval  rdb/db_delete.lua table id , roles admin
redis-cli --raw --eval  rdb/db_delete.lua table id , perms orgs
redis-cli --raw --eval  rdb/db_delete.lua table id , perms dbuser


log info 构建RBAC数据库

log debug 插入perm权限资源数据perms:id_name,orgs_user/orgs
redis-cli  --raw --eval rdb/db_insert.lua  table  id type name desc res , perms orgs uri 组织 组织机构 user/orgs
redis-cli  --raw --eval rdb/db_insert.lua  table  id type name desc res , perms dbuser db 用户表 用户数据表 users

log debug 维护role角色数据roles:id_name_perms,role_角色-perms:orgs是关联数据json格式
redis-cli  --raw --eval rdb/db_insert.lua  table  id name desc :perms , roles user 用户 普通用户角色 {orgs}
redis-cli  --raw --eval rdb/db_insert.lua  table  id name desc :perms , roles admin 管理员 超级用户角色 '{orgs,dbuser}'

log debug 维护user用户数据users:id_name_roles,user_jamesmo_role-roles:user是关联数据,json格式,roles关联表名,user关联数据主键
redis-cli  --raw --eval rdb/db_insert.lua  table  id name desc :roles , users jamesmo 莫邪 测试用户 '{user,admin}'


log debug 用户列表：用户
redis-cli --raw --eval  rdb/db_get.lua table , users


log debug 角色列表：角色
redis-cli --raw --eval  rdb/db_get.lua table , roles


log debug 权限列表：权限
redis-cli --raw --eval  rdb/db_get.lua table , perms


log debug 用户权限列表：用户 权限
echo users id name :roles:perms{id,name,res}


