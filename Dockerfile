FROM redis:alpine


MAINTAINER JamesMo <springclick@gmail.com>

ENV LANG       zh_CN.UTF-8
ENV LANGUAGE   zh_CN:zh

# 每个 RUN 增加一层，减少层数可以减少镜像包大小

#更新Alpine的软件源为国内（阿里云）的站点，因为从默认官源拉取实在太慢了。。。
RUN echo "https://mirrors.aliyun.com/alpine/v3.10/main/" > /etc/apk/repositories \
    && echo "https://mirrors.aliyun.com/alpine/v3.10/community/" >> /etc/apk/repositories \


#设置时区
RUN echo "Asia/Shanghai" > /etc/timezone

ADD localtime /etc/localtime
