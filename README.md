#Redis-Cluster-Docker

##介绍

Docker 作为强劲的计算引擎与内存存储

业务场景1：快速构建本地 redis-cluster 6节点的原生集群；

业务场景2：docker redis 镜像。

    

## 一键启动 local redis  集群；

    cd cluster-conf
    
     启动： sh start.sh 
    
     初始化集群： ./redis-trib.rb create --replicas 0 192.168.0.101:6381 192.168.0.101:6382 192.168.0.101:6383  192.168.0.101:6384  192.168.0.101:6385  192.168.0.101:6386 
     
     测试集群： redis-cli -h 192.168.0.101 -c -p 6381 
     
     常用集群指令： cluster nodes; cluster info;
     
     检测建群状态： ./redis-trib.rb check   127.0.0.1:6381 
        
    
## 一键启动 redis4docker 集群；

    fig up -d && fig logs 
    

## 构建本地镜像

    docker build -t supermy/ap-redis redis
    
## 使用镜像

    redis-cli
    127.0.0.1:6379>set a 123456
    127.0.0.1:6479>save

    常用：docker run -it --rm --name some-redis -d -p 6379:6379 supermy/ap-redis
    持久化存储：以独立日志的方式记录每次写命令，重启时再重新执行AOF文件中的命令达到恢复数据的目的。AOF的主要作用是解决了数据持久化的实时性，
        可以手动使用 save 保存数据到 dump.rdb。
        docker run -it --rm  --name some-redis -d -p 6379:6379 supermy/ap-redis redis-server --appendonly yes
        
        
    持久化存储到本地：
        docker run -it --rm --name some-redis \
                -d -p 6379:6379 \
                -v /tmp/data:/data \
                supermy/ap-redis redis-server --appendonly yes
                
            
    自定义配置文件启动：
        docker run \
            -v /myredis/conf/redis.conf:/usr/local/etc/redis/redis.conf --name myredis \
            supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf
    
    
