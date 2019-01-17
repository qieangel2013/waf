--waf.lua拦截cc攻击 cc攻击频率 (需要nginx.conf的http段增加lua_shared_dict limit 10m;)
cc_rate = "1000/60" --设置cc攻击频率，单位为秒. 默认1分钟同一个IP只能请求同一个地址10次
--useragent 配置useragent规则
useragent ={"(HTTrack|harvest|audit|dirbuster|pangolin|nmap|sqln|-scan|hydra|Parser|libwww|BBBike|sqlmap|w3af|owasp|Nikto|fimap|havij|PycURL|zmeu|BabyKrokodil|netsparker|httperf|bench| SF/)"}
--白名单IP
ipWhiteTable = {"11.25.17.18"}
--黑名单IP
ipBlackTable = {"192.168.234.1","192.168.234.2-192.168.234.5"}
--ip_limit.lua ip限制
ttl_timespan_s = {86400,5*86400,0}    --封禁时长
ip_check_timespan_s = 86400    	      --检查步长
access_threshold_count = 20000 		  --访问频率计数阈值
--redsipool.lua redis连接池配置
redis_config = {
	host = "127.0.0.1",
  	port = 6379,
  	password = "111111"
}
--输出重定向
redirect_url = "https://www.julive.com"
--返回状态码
error_status = 403
--输出格式开启将返回html提示类型(on/off)
error_output = "on"
error_output_html=[[
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>网站防火墙</title>
<style>
p {
	line-height:20px;
}
ul{ list-style-type:none;}
li{ list-style-type:none;}
</style>
</head>

<body style=" padding:0; margin:0; font:14px/1.5 Microsoft Yahei, 宋体,sans-serif; color:#555;">

 <div style="margin: 0 auto; width:1000px; padding-top:70px; overflow:hidden;">
  
  
  <div style="width:600px; float:left;">
    <div style=" height:40px; line-height:40px; color:#fff; font-size:16px; overflow:hidden; background:#6bb3f6; padding-left:20px;">网站防火墙 </div>
    <div style="border:1px dashed #cdcece; border-top:none; font-size:14px; background:#fff; color:#555; line-height:24px; height:220px; padding:20px 20px 0 20px; overflow-y:auto;background:#f3f7f9;">
      <p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;"><span style=" font-weight:600; color:#fc4f03;">您的请求带有不合法参数，已被网站管理员设置拦截！</span></p>
<p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">可能原因：您提交的内容包含危险的攻击请求</p>
<p style=" margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px; -qt-block-indent:1; text-indent:0px;">如何解决：</p>
<ul style="margin-top: 0px; margin-bottom: 0px; margin-left: 0px; margin-right: 0px; -qt-list-indent: 1;"><li style=" margin-top:12px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">1）检查提交内容；</li>
<li style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">2）如网站托管，请联系空间提供商；</li>
<li style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">3）普通网站访客，请联系网站管理员；</li></ul>
    </div>
  </div>
</div>
</body></html>
]]
---配置文件项
--waf 
local waf = require "waf"

local utils = require "lua_utils"
local clientip = utils.get_clientip()

-- local uidLimit = require "uid_limit"
-- local uidL = uidLimit:new()

local ipLimit = require "ip_limit"
local iplimit = ipLimit:new()

--输出格式化
function output_print(data)
	if error_output == 'on' then
		ngx.header.content_type = "text/html"
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.say(error_output_html)
        ngx.exit(ngx.status)
	else
		ngx.exit(data)
	end
end


--waf过滤 黑名单过滤
local blacktatus = waf.black_ip_check()
if blacktatus and blacktatus ~= 1 then
	output_print(blacktatus)
end
--waf过滤 cc攻击
local wafstatus = waf.cc_attack_check()
if wafstatus and wafstatus ~= 1 then
	output_print(wafstatus)
end
--waf过滤 useragent过滤
local wafastatus = waf.user_agent_attack_check()
if wafastatus and wafastatus ~= 1 then
	output_print(wafastatus)
end
--单IP单uid固定接口 组合限制
--当某一uid被限流时尽量不影响该IP内的其他用户
-- local ok1 = uidL.check_uid_freq()
-- if ok1 and ok1 ~= 1 then
-- 	ngx.exit(ok1)
-- end
--单IP全局限流检查
local ok = iplimit.check_ip_freq()
if ok and ok ~= 1 then
	output_print(ok)
end
