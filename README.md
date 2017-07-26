#Redis-Cluster-Docker

##介绍

Docker 作为强劲的计算引擎与内存存储

业务场景1：快速构建本地 redis-cluster 6节点的原生集群；

业务场景2：docker redis 镜像。


## 一键启动 local redis  集群；

    cd cluster-conf
    
     启动： sh start.sh 
    
     初始化集群： ./redis-trib.rb create --replicas 0 192.168.0.122:6381 192.168.0.122:6382 192.168.0.122:6383  192.168.0.122:6384  192.168.0.122:6385  192.168.0.122:6386 
     
     测试集群： redis-cli -h 192.168.0.122 -c -p 6381 
     
     常用集群指令： cluster nodes; cluster info;
     
     检测建群状态： ./redis-trib.rb check   127.0.0.1:6381 
        
    
## 一键启动 redis4docker 集群；

    fig up -d && fig logs 
    

## 构建本地镜像

    docker build -t supermy/ap-redis redis
