--waf处理逻辑
local utils = require "lua_utils"
local client_ip = utils.get_clientip()
local rulematch = ngx.re.find
local _M = {}

function _M.new(self)
    return self
end
-- ip转换
function _M.ipToDecimal(ckip)
    local n = 4
    local decimalNum = 0
    local pos = 0
    for s, e in function() return string.find(ckip, '.', pos, true) end do
        n = n - 1
        decimalNum = decimalNum + string.sub(ckip, pos, s-1) * (256 ^ n)
        pos = e + 1
        if n == 1 then decimalNum = decimalNum + string.sub(ckip, pos, string.len(ckip)) end
    end
    return decimalNum
end
--deny cc attack
function _M.cc_attack_check(self)
    local ATTACK_URI=ngx.var.uri
    local CC_TOKEN = client_ip..ATTACK_URI
    local limit = ngx.shared.limit
    CCcount=tonumber(string.match(cc_rate,'(.*)/'))
    CCseconds=tonumber(string.match(cc_rate,'/(.*)'))
    local req,_ = limit:get(CC_TOKEN)
    if req then
        if req > CCcount and not(_M.white_ip_check()) then
            return error_status
        else
            limit:incr(CC_TOKEN,1)
        end
    else
        limit:set(CC_TOKEN,1,CCseconds)
    end
end
--deny user agent
function _M.user_agent_attack_check(self)
    local USER_AGENT = ngx.var.http_user_agent
    if USER_AGENT ~= nil then
        for _,rule in pairs(useragent) do
            if rule ~="" and rulematch(USER_AGENT,rule,"jo") then
                return error_status
            end
        end
    end
end
--allow white ip
function _M.white_ip_check(self)
    if next(ipWhiteTable) ~= nil then
        local numIP = 0
        if client_ip ~= "unknown" then 
            numIP = tonumber(_M.ipToDecimal(client_ip))  
        end
        for _,rule in pairs(ipWhiteTable) do
            local s, e = string.find(rule, '-', 0, true)
            if s == nil and client_ip == rule then
                return true
            elseif s ~= nil then
                sIP = tonumber(_M.ipToDecimal(string.sub(rule, 0, s - 1)))
                eIP = tonumber(_M.ipToDecimal(string.sub(rule, e + 1, string.len(rule))))
                if numIP >= sIP and numIP <= eIP then
                   return true
                end
            end
        end
    end
    return false
end

--deny black ip
function _M.black_ip_check(self)
    if next(ipBlackTable) ~= nil then
        local numIP = 0
        if client_ip ~= "unknown" then 
            numIP = tonumber(_M.ipToDecimal(client_ip))  
        end
        for _,rule in pairs(ipBlackTable) do
            local s, e = string.find(rule, '-', 0, true)
            if s == nil and client_ip == rule then
                return error_status
            elseif s ~= nil then
                sIP = tonumber(_M.ipToDecimal(string.sub(rule, 0, s - 1)))
                eIP = tonumber(_M.ipToDecimal(string.sub(rule, e + 1, string.len(rule))))
                if numIP >= sIP and numIP <= eIP then
                   return error_status
                end
            end
        end
    end
end
return _M
