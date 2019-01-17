local key_prefix_isdeny = "globalipfreq_isdeny_"
local key_prefix_stime = "globalipfreq_stime_"
local key_prefix_step = "globalipfreq_step_"
local key_prefix_count = "globalipfreq_count_"

local _M = {}

function _M.new(self)
	return self
end

function _M.check_ip_freq(self)
	local utils = require "lua_utils"
	local client_ip = utils.get_clientip()

	local rds_key = client_ip

	--获取redis连接
	local redis = require "redispool"
	local rds = redis.new()
	--如果连接失败、redis丢失服务等 按无限制操作
	if not rds then
		return 1
	end
	--查询ip是否在封禁段内，若在则返回http错误码
	--封禁时间段内不再对ip时间和计数做处理
	local is_deny , err = rds:get(key_prefix_isdeny..rds_key)
	local ipstep , err = rds:get(key_prefix_step..rds_key)
	if tonumber(ipstep) == nil or tonumber(ipstep)  == '' then
		ipstep = 1
	end
	if tonumber(is_deny) == 1 then
		ngx.log(ngx.ERR,"globalipfreq_deny ","ip: "..rds_key.." : deny timespan : "..ttl_timespan_s[tonumber(ipstep)])
		rds:close()
		return error_status
	end

	local start_time , err = rds:get(key_prefix_stime..rds_key)
	local count , err = rds:get(key_prefix_count..rds_key)
	--如果ip记录时间大于指定时间间隔或者记录时间不存在,则初始化记录时间、计数
	--如果IP访问的时间间隔小于约定的时间间隔，则ip计数正常加1，且如果ip计数大于约定阈值，则设置ip的封禁key为1,即将此IP拉黑 ,同时设置封禁IP的数据过期时间
	if (start_time == ngx.null or (os.time() - start_time) >= ip_check_timespan_s) and ttl_timespan_s[tonumber(ipstep)] ~= 0 then
		res , err = rds:set(key_prefix_stime..rds_key , os.time())
		rds:expire(key_prefix_stime..rds_key,ttl_timespan_s[tonumber(ipstep)])
		res , err = rds:set(key_prefix_count..rds_key , 1)
		rds:expire(key_prefix_count..rds_key,ttl_timespan_s[tonumber(ipstep)])
		rds:close()
		return 1
	else
		if count == ngx.null and ttl_timespan_s[tonumber(ipstep)] ~= 0 then
			rds:set(key_prefix_count..rds_key , 1)
			rds:expire(key_prefix_count..rds_key,ttl_timespan_s[tonumber(ipstep)])
		else 
			if(ttl_timespan_s[tonumber(ipstep)] ~= 0) then
				count = count + 1
				res , err = rds:incr(key_prefix_count..rds_key)
				if count >= access_threshold_count then
					res , err = rds:set(key_prefix_isdeny..rds_key,1)
					res , err = rds:incr(key_prefix_step..rds_key)
					res , err = rds:expire(key_prefix_isdeny..rds_key,ttl_timespan_s[tonumber(ipstep)])
					ngx.log(ngx.ERR,"globalipfreq_deny ","ip: "..rds_key.." : deny timespan : "..ttl_timespan_s[tonumber(ipstep)])
					rds:close()
					return error_status
				end
			else
				res , err = rds:set(key_prefix_isdeny..rds_key,1)
			end
		end
		rds:close()
	end
end

return _M