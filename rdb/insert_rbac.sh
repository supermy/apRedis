##主键关联数据
### 插入perm 权限资源数据     perms: id name,orgs user/orgs
redis-cli  --raw --eval rdb/db_insert.lua  table  id name desc res , perms orgs 组织 组织机构 user/orgs

### 维护role角色数据；    roles: id name perms,role role orgs ;perms:orgs 是关联数据，json 格式
redis-cli  --raw --eval rdb/db_insert.lua  table  id name desc perms , roles user 用户 普通用户角色 orgs

### 维护user用户数据：    insert_user_data.lua id name roles,user jamesmo role ; roles:user 是关联数据,json 格式
redis-cli  --raw --eval rdb/db_insert.lua  table  id name desc roles , users jamesmo 莫邪 一般用户 user

###用户与角色
redis-cli  --raw --eval rdb/db_insert.lua  table  id  , userroles jamesmo_user

###角色与权限
redis-cli  --raw --eval rdb/db_insert.lua  table  id  , roleperms user_orgs


### 用户列表：角色，权限


### 角色列表：权限，用户


### 权限列表：角色，用户


### 用户权限列表：用户 权限