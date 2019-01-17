### 安装部分
 	wget -c http://luajit.org/download/LuaJIT-2.0.4.tar.gz
	tar xzvf LuaJIT-2.0.4.tar.gz
	cd LuaJIT-2.0.4
	make install PREFIX=/usr/local/luajit
	注意环境变量!
	export LUAJIT_LIB=/usr/local/luajit/lib
	export LUAJIT_INC=/usr/local/luajit/include/luajit-2.0
	2.下载解压ngx_devel_kit
	wget https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz
	tar -xzvf v0.3.0.tar.gz
	3.下载解压lua-nginx-module
	wget https://github.com/openresty/lua-nginx-module/archive/v0.10.13.tar.gz
	tar -xzvf v0.10.8.tar.gz
	nginx -V查看编译参数
	原有编译参数加上--add-module=/usr/local/lua/ngx_devel_kit-0.3.0 --add-module=/usr/local/lua/lua-nginx-module-0.10.9rc7
	如果出现下面错误
	./configure: error: ngx_http_lua_module requires the Lua library.
	yum -y install lua-devel
	再重新执行编译
	./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --without-http-cache --with-http_ssl_module --with-http_gzip_static_module --with-http_realip_module --add-module=/usr/local/lua/ngx_devel_kit-0.3.0 --add-module=/usr/local/lua/lua-nginx-module-0.10.9rc7
	注意ngx_devel_kit和lua-nginx-module以实际解压路径为准
	make -j2
	make install
### 使用配置部分
	lua脚本包括以下几个文件
	access_limit.lua 入口文件，包括配置项都在这里
    --waf.lua拦截cc攻击 cc攻击频率 (需要nginx.conf的http段增加lua_shared_dict limit 10m;)
	cc_rate = "10/60" --设置cc攻击频率，单位为秒. 默认1分钟同一个IP只能请求同一个地址10次
    --useragent 配置useragent规则
	useragent ={"(HTTrack|harvest|audit|dirbuster|pangolin|nmap|sqln|-scan|hydra|Parser|libwww|BBBike|sqlmap|w3af|owasp|Nikto|fimap|havij|PycURL|zmeu|BabyKrokodil|netsparker|httperf|bench| SF/)"}
    --白名单IP
	ipWhiteTable = {"11.25.17.18"}
    --黑名单IP
	ipBlackTable = {"192.168.234.1","192.168.234.2-192.168.234.5"}
    --ip_limit.lua ip限制
	ttl_timespan_s = {86400,5*86400,0} --封禁时长（0代表永久，86400代表一天，此处以秒为单位）
    ip_check_timespan_s = 86400 --检查步长 （检查周期，此处配置以一天为单位）
 	access_threshold_count = 200 --访问频率计数阈值 （此处配置代表一个周期时间内访问的频率配置，如果设置了白名单，此处配置无效）
    --redsipool.lua redis连接池配置
	redis_config = {
		host = "127.0.0.1",
		port = 6379,
        -- password = "password"
	}
    --输出重定向
	redirect_url = "https://www.julive.com"
    --返回状态码
	error_status = 403
    --输出格式开启将返回html提示类型(on/off)
	error_output = "on"
	error_output_html=[[此处省略]]
    ---配置文件项
	注意：在此处配置的优先级是 黑名单>白名单>cc攻击>ip限制

	ip_limit.lua   ip限制文件

	lua_utils.lua 工具类文件

	redispool.lua redis连接池文件

	waf.lua  实现waf功能文件
### nginx 配置
	http段加入如下配置项
	lua_package_path "/usr/local/nginx/lua/?.lua;;";
	lua_shared_dict limit 10m;
	access_by_lua_file lua/access_limit.lua;