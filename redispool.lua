local redis = require "resty.redis"
local _M = {}

--获取redis连接
function _M.new(self)
    local red = redis:new()
    red:set_timeout(20) -- one second timeout
    local res = red:connect(redis_config['host'], redis_config['port'])
    if not res then
        return nil
    end
    if redis_config['password'] ~= nil then
		res = red:auth(redis_config['password'])
	    if not res then
	        return nil
	    end
    end
    red.close = close
    return red
end
--归还连接到连接池 以备复用
function close(self)
    self:set_keepalive(120000, 50)
end

return _M