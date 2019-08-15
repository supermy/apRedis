
### 插入perm 权限资源数据     perms: id name,orgs user/orgs
redis-cli  --raw --eval rdb/insert_db_data.lua  table  id name desc res , perms orgs 组织 组织机构 user/orgs

### 维护role角色数据；    roles: id name perms,role role orgs ;perms:orgs 是关联数据，json 格式
redis-cli  --raw --eval rdb/insert_db_data.lua  table  id name desc perms , roles user 用户 普通用户 orgs,

### 维护user用户数据：    insert_user_data.lua id name roles,user jamesmo role ; roles:user 是关联数据,json 格式
redis-cli  --raw --eval rdb/insert_db_data.lua  table  id name desc roles , users jamesmo 莫邪 一般用户 user,

### 用户列表：角色，权限


### 角色列表：权限，用户


### 权限列表：角色，用户

