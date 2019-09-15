Access = {}
Access.__index = Access

function Access:new()
	local o = {}
        setmetatable(o,Access)
        o.exist = true
        o.emails = {}
	o.usernames = {}
        o.email_mode = "default"
	o.cookie_prefix = "luarestyaccess_"
        o.access_time = 3600
        o.access_persistent = false
	return o
end

function Access:configure(options)
	if options.cookie_prefix then self.cookie_prefix = options.cookie_prefix end
	if options.access_time then self.access_time = options.access_time end
	if options.access_persistent then self.access_persistent = options.access_persistent end
	return true
end

function Access:emailConfig(options)
        if not (options.mode and options.host and options.port and options.tls and options.username and options.password and self.exist) then return false end
	self.email_mode = options.mode
	self.smtpHost = options.host
	self.smtpPort = options.port
	self.smtpTls = options.tls
	self.smtpUsername = options.username
        self.smtpPassword = options.password
	return true
end

function Access:permitUser(options)
        if not(options.username and options.account and self.exist) then return false end
	local table = {}
	table['type'] = "email"
	table['account'] = options.account
	self.usernames[options.username] = table 
	return true
end

function Access:permitEmail(options)
	if not(options.email and self.exist) then return false end
	self.emails[options.email] = true
	return true
end

function Access:protect()
local session_secret = "623q4hR325t36VsCD3g567922IC0073T"

local email_config = {}
if self.email_mode == "default" then 
	email_config['mode'] = "default" 
end
if self.email_mode == "smtp" then 
	email_config['mode'] = self.email_mode
	email_config['host'] = self.smtpHost
	email_config['port'] = self.smtpPort
	email_config['starttls'] = self.smtpTls
	email_config['username'] = self.smtpUsername
	email_config['password'] = self.smtpPassword
end
local prefix_session_name = self.cookie_prefix
local access_session_cookie_lifetime = self.access_time
local access_session_cookie_persistent = self.access_persistent

local always_same_secret = "623q4hR325t36VsCD3g567922IC0073T"
local email = require "resty.access.email_actions"
local cjson = require 'cjson.safe'
local random = require "resty.random"
local str = require "resty.string"
local sha1 = require "resty.sha1"

local access_session = require "resty.session".new()
if session_secret then access_session.secret = session_secret end 
access_session.name = prefix_session_name .. "cookie"
access_session.cookie.lifetime = access_session_cookie_lifetime
access_session.cookie.persistent = access_session_cookie_persistent
access_session.cookie.renew = 0
access_session.cookie.samesite = "Strict"

local authen_session = require "resty.session".new()
if session_secret then authen_session.secret = session_secret end
authen_session.name = prefix_session_name .. "challenge"
authen_session.cookie.renew = 0
authen_session.cookie.lifetime = 60
authen_session.cookie.samesite = "Strict"

local names_session = require "resty.session".new()
if session_secret then names_session.secret = always_same_secret end
names_session.name = prefix_session_name .. "data"
names_session.cookie.lifetime = 10^9
names_session.cookie.persistent = true
names_session.cookie.samesite = "Strict"

access_session:open()

if access_session.present then
	access_session:hide()
	names_session:hide()
	return
end

ngx.req.read_body()
local post_args = ngx.req.get_post_args()
local user, code = false
if post_args['code'] then code = post_args['code'] end
if post_args['user'] then user = post_args['user'] end
if ngx.var.arg_code then code = ngx.var.arg_code end
names_session:open()
local lastuser = names_session.data.user or false
local Response = require 'resty.access.index'

if user then
	local account = false
	local type = false
	if self.usernames[user] then
		account = self.usernames[user]['account']
		type = self.usernames[user]['type']
	else
	
		for pattern in pairs(self.emails) do
			pattern = pattern:gsub("%%","")
			pattern = pattern:gsub("([%^%$%(%)%.%[%]%+%-%?])", "%%%1")
			pattern = pattern:gsub("%*", ".*")
			pattern = "^"..pattern.."$"
			if string.match(user,pattern) and email.check(user) then
				account = user
				type = "email"
			end
		end
	end 
		
	if not account then
		Response({lastuser = lastuser,error = 'You are not welcome here'})
	end	
  
	local digest = sha1:new()
		digest:update(user)
		digest:update(always_same_secret)
		digest = str.to_hex(digest:final())
	local users = ngx.shared.luarestyaccess
	users:set(digest,user,authen_session.cookie.lifetime)
	authen_session:start()
		authen_session.data.otp = string.sub(string.format( "%d", tonumber(str.to_hex(random.bytes(6,true) or random.bytes(6)),16)),1,6)
		authen_session.data.id = digest
		authen_session.data.location = ngx.var.uri
	authen_session:save()
	
	if type == "email" then 
		if not email.send(account,authen_session.data.otp,ngx.req.get_headers()["Host"],email_config) then
			authen_session:destroy()
			Response({lastuser=user, error = 'Problem with sending email'})
		end
		Response({lastuser = user,otp = true})
	end
end

authen_session:open()		

if code and authen_session.data.otp then
	local users = ngx.shared.luarestyaccess
	local user,attempts = users:get(authen_session.data.id)
	local location = user['location'] or "/"
	if attempts == nil then attempts = 0 end
	if attempts >= 3 then
		Response({lastuser = user})
	end

	if code == authen_session.data.otp then
		users:set(authen_session.data.id,user,users:ttl(authen_session.data.id),3)
		access_session:start()
			access_session.data.user = authen_session.data.user
			access_session.data.access = true
			access_session:save()
		names_session:start()
			names_session.data.user = authen_session.data.user
		names_session:save()
		ngx.redirect(authen_session.data.location) 
		authen_session:destroy()
	else
		users:set(authen_session.data.id,user,users:ttl(authen_session.data.id),attempts+1) 
		if attempts + 1 == 3 then
			authen_session:destroy()
			Response({lastuser = lastuser, error = "Get yourself a new one."})
		else
			Response({otp = true, error= "Code is wrong."})
		end	
	end
end

Response({lastuser = lastuser})
end

return Access
