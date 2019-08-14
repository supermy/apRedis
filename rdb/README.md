#Redis-Lua-RBAC

##介绍

使用 lua-redis 实现RBAC权限资源管理系统
    

## 维护 perm 数据；
    insert_perm_data.lua id name,orgs user/orgs        
    
## 维护 role 数据；
    insert_role_data.lua id name perms,role role orgs 
    
## 维护用户数据：
    insert_role_data.lua id name roles,user jamesmo role 
      
    
## Base 脚本 insert_data.lua  table  id name desc res, idvalue namevalue descvalue resvalue :id,name is reqquir        
   
    
    
## RBAC 数据结构
     
    权限：perm:string
    SADD permissions userorgs
    HMSET permission_id_userorgs perm "/user/orgs"
    
    角色：perms:json 格式
    SADD roles user
    HMSET role_id_role name "role" perms "orgs,"
    
    用户：roles:json 格式
    SADD users JamesMo
    HMSET user_id_JamesMo name "莫爷" roles "user,"
    

    SELECT  a.id,a.permission from permission a ,role_permission b,role c,user_role d,user e WHERE a.id=b.permission_id and c.id=b.role_id and d.role_id=c.id and d.user_id=e.id and e.id=1"

    INSERT INTO `permission` VALUES ('1', '/user/orgs');
    INSERT INTO `role` VALUES ('1', 'user');
    INSERT INTO `role_permission` VALUES ('1', '1', '1');
    INSERT INTO `user` VALUES ('1', 'forezp');
    INSERT INTO `user_role` VALUES ('1', '1', '1');

    CREATE TABLE `user` (
    `id`  int(11) NOT NULL AUTO_INCREMENT ,
    `name`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
    PRIMARY KEY (`id`)
    )

    CREATE TABLE role(
    `id`  int(11) NOT NULL AUTO_INCREMENT ,
    `name`  varchar(255) CHARACTER SET latin5 NULL DEFAULT NULL ,
    PRIMARY KEY (`id`)
    )


    CREATE TABLE permission(
    `id`  int(11) NOT NULL AUTO_INCREMENT ,
    `permission`  varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NULL DEFAULT NULL ,
    PRIMARY KEY (`id`)
    )

    CREATE TABLE user_role(
    `id`  int(11) NOT NULL AUTO_INCREMENT ,
    `user_id`  int(11) NULL DEFAULT NULL ,
    `role_id`  int(11) NULL DEFAULT NULL ,
    PRIMARY KEY (`id`)
    )
    
    CREATE TABLE role_permission(
    `id`  int(11) NOT NULL AUTO_INCREMENT ,
    `role_id`  int(11) NULL DEFAULT NULL ,
    `permission_id`  int(11) NULL DEFAULT NULL ,
    PRIMARY KEY (`id`)
    )

   