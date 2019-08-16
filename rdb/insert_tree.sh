#插入一个数的数据节点

redis-cli --raw  --eval rdb/insert_tree_data.lua  tree  id name parentid , orgtree beijing 北京 root
redis-cli --raw  --eval rdb/insert_tree_data.lua  tree  id name parentid , orgtree bjcity 北京市 root@beijing
redis-cli --raw  --eval rdb/insert_tree_data.lua  tree  id name parentid , orgtree xcq 西城区 root@beijing@bjcity
redis-cli --raw  --eval rdb/insert_tree_data.lua  tree  id name parentid , orgtree hdq 海淀区 root@beijing@bjcity
