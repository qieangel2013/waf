http段加入如下配置项
lua_package_path "/usr/local/nginx/lua/?.lua;;";
lua_shared_dict limit 10m;
access_by_lua_file lua/access_limit.lua;