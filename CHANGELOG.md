
### 2019-08-11 
    升级 alpine3.0

### 2017-07-26
    
    项目迁移    

### 2017-07-14

    ./redis-trib.rb create --replicas 0 192.168.0.122:6381 192.168.0.122:6382 192.168.0.122:6383  192.168.0.122:6384  192.168.0.122:6385  192.168.0.122:6386 
    redis-cli -h 192.168.0.122 -c -p 6381 
    ./redis-trib.rb check   127.0.0.1:6381 


### 2017-06-29

集群搭建

    Download from above
    Unpack into a directory and cd there
    Install with: ruby setup.rb (you may need admin/root privilege)

    ruby setup.rb
    gem install  redis --version 3.0.0

    gem install redis --version 3.0.0  
    #由于源的原因，可能下载失败，就手动下载下来安装  
    #download地址:http://rubygems.org/gems/redis/versions/3.0.0  
    gem install -l /data/soft/redis-3.0.0.gem  


    手动启动
    redis-server /etc/rediscluster.conf 
    ./redis-trib.rb create --replicas 0 132.194.43.146:6379 132.194.43.147:6379 132.194.43.153:6379 132.194.43.172:6379 132.194.43.173:6379 132.194.43.174:6379   
    ./redis-trib.rb check   192.168.0.122:6381 
    ./redis-trib.rb check   127.0.0.1:6381 
    
    
###2016-12-17
####docker 集群模式
fig up -d 
./redis-trib.rb create --replicas 0 192.168.0.122:6381 192.168.0.122:6382 192.168.0.122:6383  192.168.0.122:6384  192.168.0.122:6385  192.168.0.122:6386 
todo 需要优化docker 通过内部网络的启动方式
redis-cli -h 192.168.0.122 -c -p 6381 

###2016-12-16
####集群模式
redis 集群至少需要6个节点，启动成功。
手动启动-recis-cluster启动节点
sh start.sh
创建集群
./redis-trib.rb create --replicas 1 127.0.0.1:6381 127.0.0.1:6382 127.0.0.1:6383  127.0.0.1:6384  127.0.0.1:6385  127.0.0.1:6386 
集群测试：命令后，切忌要加入-c，否则我们进入的不是集群环境。
redis-cli -h 127.0.0.1 -c -p 6381 


###2016-09-18
####主从模式
####docker run --net=host --name=master supermy/ap-redis
####docker run --net=host --name=slave -d supermy/ap-redis redis-server --port 6380 --slaveof 127.0.0.1 6379
*   docker exec -it master redis-cli
*   set aaa 123
*   keys *
*   get aaa
*   exit
*   docker exec -it slave redis-cli
*   keys *
*   get aaa
-   返回数据是123,数据已经同步
*   exit
####docker rm -f master slave

###集群

>    cat << EOF > redis1.conf   
 
    port 6381
    cluster-enabled yes
    cluster-config-file nodes.conf
    cluster-node-timeout 5000
    appendonly yes
    EOF
    
>    cp redis1.conf redis2.conf

    sed -i '' 's/6381/6382/' redis2.conf
    
>    cp redis1.conf redis3.conf

    sed -i ''  's/6381/6383/' redis3.conf

>   net=host to fix me 
    docker run -p 6381:6381 --name=redis1 -v `pwd`/redis1.conf:/usr/local/etc/redis/redis.conf -d supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf
    docker run -p 6382:6382 --name=redis2 -v `pwd`/redis2.conf:/usr/local/etc/redis/redis.conf -d supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf
    docker run -p 6383:6383 --name=redis3 -v `pwd`/redis3.conf:/usr/local/etc/redis/redis.conf -d supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf


*   git clone https://github.com/antirez/redis

*   sudo gem install redis

*   ruby redis-trib.rb create 127.0.0.1:6381 127.0.0.1:6382 127.0.0.1:6383

>
    docker exec -it redis1 redis-cli -p 6381
    cluster nodes
    set aaa 123
    set bbb 234
    exit

>   redis-cli提供了一个-c的参数，允许以集群的方式连接
    docker exec -it redis1 redis-cli -c -p 6381
    set bbb 234
    keys *
    exit

####docker rm -f redis1 redis2 redis3


##主从集群
>
cp redis1.conf redis4.conf
cp redis1.conf redis5.conf
cp redis1.conf redis6.conf

sed -i 's/6381/6384/' redis4.conf
sed -i 's/6381/6385/' redis5.conf
sed -i 's/6381/6386/' redis6.conf

docker run --net=host --name=redis1 -v `pwd`/redis1.conf:/usr/local/etc/redis/redis.conf -d supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf
docker run --net=host --name=redis2 -v `pwd`/redis2.conf:/usr/local/etc/redis/redis.conf -d supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf
docker run --net=host --name=redis3 -v `pwd`/redis3.conf:/usr/local/etc/redis/redis.conf -d supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf
docker run --net=host --name=redis4 -v `pwd`/redis4.conf:/usr/local/etc/redis/redis.conf -d supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf
docker run --net=host --name=redis5 -v `pwd`/redis5.conf:/usr/local/etc/redis/redis.conf -d supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf
docker run --net=host --name=redis6 -v `pwd`/redis6.conf:/usr/local/etc/redis/redis.conf -d supermy/ap-redis redis-server /usr/local/etc/redis/redis.conf

####ruby redis/src/redis-trib.rb create --replicas 1 127.0.0.1:6381 127.0.0.1:6382 127.0.0.1:6383 127.0.0.1:6384 127.0.0.1:6385 127.0.0.1:6386
####docker rm -f redis1 redis2 redis3 redis4 redis5 redis6



2016-08-25
    启动实例
    $ docker run  -d -p 6379  supermy/ap-redis
    持久化配置
    $ docker run --name some-redis -d redis redis-server --appendonly yes
    链接到应用
    $ docker run --name some-app --link some-redis:redis -d application-that-uses-redis
    应用到redis-cli
    $ docker run -it --link some-redis:redis --rm redis redis-cli -h redis -p 6379
    自定义配置文件启动
    $ docker run -v /myredis/conf/redis.conf:/usr/local/etc/redis/redis.conf 
        --name myredis redis redis-server /usr/local/etc/redis/redis.conf

    docker run --name some-redis -d redis

    
2016-06-23
    8M  迷你
    docker pull redis:alpine   
    docker run --name some-redis -d redis:alpine
    
    #启动持久化存储，制定存储到本地绑定目录 -v /docker/host/dir:/data
    docker run --name some-redis -d redis redis-server --appendonly yes
    
    connect to it from an application
    $ docker run --name some-app --link some-redis:redis -d application-that-uses-redis
    ... or via redis-cli
    $ docker run -it --link some-redis:redis --rm redis redis-cli -h redis -p 6379
   
    