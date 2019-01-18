local _M = {}

function _M.new(self)
	return self
end
--获取客户端IP
function _M.get_clientip(self)
	local client_ip = ngx.req.get_headers()["X-Real-IP"]
	if client_ip == nil then
		client_ip = ngx.req.get_headers()["x_forwarded_for"]
	end

	if client_ip == nil then
		client_ip = ngx.var.remote_addr
	end
	return client_ip
end
--写入文件
function _M.write(logfile,msg)
    local fd = io.open(logfile,"ab")
    if fd == nil then return end
    fd:write(msg)
    fd:flush()
    fd:close()
end
--写日志
function _M.log(method,url,data,ruletag)
    if logpath ~= nil and logpath ~='' then
        local realIp = _M.get_clientip()
        local ua = ngx.var.http_user_agent
        local servername=ngx.var.server_name
        local time=ngx.localtime()
        if ua  then
            line = realIp.." ["..time.."] \""..method.." "..servername..url.."\" \""..data.."\"  \""..ua.."\" \""..ruletag.."\"\n"
        else
            line = realIp.." ["..time.."] \""..method.." "..servername..url.."\" \""..data.."\" - \""..ruletag.."\"\n"
        end
        local filename = logpath..'/'..servername.."_"..ngx.today().."_sec.log"
        _M.write(filename,line)
    end
end

return _M