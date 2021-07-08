
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
        o.auth_cookie_lifetime = 60
        o.access_persistent = false
	return o
end

function Access:sessionConfig(options)
	if options.cookie_prefix then self.cookie_prefix = options.cookie_prefix end
	if options.cookie_domain then self.cookie_domain = options.cookie_domain end
	if options.access_time then self.access_time = options.access_time end
	if options.access_persistent then self.access_persistent = options.access_persistent end
	if options.access_secret then self.access_secret = options.access_secret end
	if options.auth_cookie_lifetime then self.auth_cookie_lifetime = options.auth_cookie_lifetime end
	return true
end

function Access:emailConfig(options)
    if not (options.mode and options.host and options.port and self.exist) then return false end
	self.email_mode = options.mode
	self.smtpHost = options.host
	self.smtpPort = options.port
	self.smtpTls = options.tls
	self.smtpUsername = options.username
	self.smtpPassword = options.password
	self.domain = options.domain
	self.from = options.from
	return true
end

function Access:localization(options)
	self.title1 = options.title1
	self.text1 = options.text1
	self.text2 = options.text2
	self.text3 = options.text3
	self.text4 = options.text4
	self.text5 = options.text5
	self.text6 = options.text6
	self.placeholder = options.placeholder
	self.btn1 = options.btn1
	self.btn2 = options.btn2
	self.btn3 = options.btn3
	self.btn4 = options.btn4
	self.mail1 = options.mail1
    self.mail2 = options.mail2
	self.mail3 = options.mail3
	self.mail4 = options.mail4
	self.err1 = options.err1
	self.err2 = options.err2
	self.err3 = options.err3
	self.err4 = options.err4
	return true
end

function Access:permitUser(options)
        if not(options.username and options.email and self.exist) then return false end
	local table = {}
	table['type'] = "email"
	table['account'] = options.email
	self.usernames[options.username] = table 
	return true
end

function Access:permitEmail(options)
	if not(options.email and self.exist) then return false end
	self.emails[options.email] = true
	return true
end

function Access:protect()

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
	email_config['domain'] = self.domain
	email_config['from'] = self.from
end

local localization = {}
localization['title1'] = self.title1 or "Access restricted"
localization['text1'] = self.text1 or "To enter"
localization['text2'] = self.text2 or "please confirm your right to do so."
localization['text3'] = self.text3 or "Get a login code sent to you:"
localization['text4'] = self.text4 or "A code for"
localization['text5'] = self.text5 or "has been sent to you."
localization['text6'] = self.text6 or "Enter it below to complete your login:"
localization['placeholder'] = self.placeholder or "type your username/email"
localization['btn1'] = self.btn1 or "Let me in!"
localization['btn2'] = self.btn2 or "Access"
localization['btn3'] = self.btn3 or "Re-send Code"
localization['btn4'] = self.btn4 or "Back"
localization['mail1'] = self.mail1 or "Finish your login to "
localization['mail2'] = self.mail2 or "Copy and paste the code below into the login screen"
localization['mail3'] = self.mail3 or "This code will expire in 1 minute."	
localization['mail4'] = self.mail4 or "Login code for"
localization['err1'] = self.err1 or "You are not welcome here"
localization['err2'] = self.err2 or "Problem with sending email"
localization['err3'] = self.err3 or "Get yourself a new one."
localization['err4'] = self.err4 or "Code is wrong."

local prefix_session_name = self.cookie_prefix
local access_session_cookie_lifetime = self.access_time
local access_session_cookie_persistent = self.access_persistent
local access_session_cookie_domain = self.cookie_domain
local access_session_secret = self.access_secret
local authen_session_cookie_lifetime = self.auth_cookie_lifetime

local always_same_secret = "623q4hR325t36VsCD3g567922IC0073T"
local email = require "resty.access.email_actions"
local cjson = require 'cjson.safe'
local random = require "resty.random"
local str = require "resty.string"
local sha1 = require "resty.sha1"
local Response = require 'resty.access.index'

local access_session = require "resty.session".new()
if access_session_secret then access_session.secret = access_session_secret end 
access_session.name = prefix_session_name .. "cookie"
access_session.cookie.lifetime = access_session_cookie_lifetime
access_session.cookie.persistent = access_session_cookie_persistent
access_session.cookie.domain = access_session_cookie_domain
access_session.cookie.renew = 0
access_session.cookie.samesite = "Strict"

local authen_session = require "resty.session".new()
authen_session.name = prefix_session_name .. "challenge"
authen_session.cookie.renew = 0
authen_session.cookie.lifetime = authen_session_cookie_lifetime
authen_session.cookie.samesite = "Strict"

local names_session = require "resty.session".new()
names_session.secret = always_same_secret
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
local post_args,err2  = ngx.req.get_post_args()
local name, user, code = false 
local user_controller, code_controller = false
if post_args['user'] then user = post_args['user'] end
if post_args['code'] then code = post_args['code'] end
if post_args['name'] then name = post_args['name'] end

if user and (not code or not name) then 
	user_controller = true 
 	code_controller = false
else
	authen_session:open()		
end

if code and name and not user and authen_session.data.otp then
	user_controller = false
	code_controller = true 
end
	
names_session:open()
local lastuser = names_session.data.user or false

if (not user_controller and not code_controller) or err or err2 then Response({lastuser = lastuser}, localization) end

if user_controller then
	local account,type,found = false
	if self.usernames[user] then
		account = self.usernames[user]['account']
		type = self.usernames[user]['type']
		found = true
	end
	if not found then 
		for pattern in pairs(self.emails) do
			pattern = pattern:gsub("%%","")
			pattern = pattern:gsub("([%^%$%(%)%.%[%]%+%-%?])", "%%%1")
			pattern = pattern:gsub("%*", ".*")
			pattern = "^"..pattern.."$"
			if string.match(user,pattern) then
				account = user
				type = "email"
				found = true
			end
		end
	end 
	if not found then 
		ngx.log(ngx.ALERT,"user not exist '"..user.."' from "..ngx.var.remote_addr)
		Response({lastuser = lastuser,error = localization['err1']}, localization) 
	end
	if found then	
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
			if not email.send(account,authen_session.data.otp,ngx.req.get_headers()["Host"],ngx.var.uri,email_config,localization) then
				authen_session:destroy()
				Response({lastuser=user, error = localization['err2']}, localization)
			else 
				Response({lastuser = user,otp = true}, localization)
			end
		end
	end
end


if code_controller then
	local users = ngx.shared.luarestyaccess
	local user,attempts = users:get(authen_session.data.id)
	local location = authen_session.data.location or "/"
	if attempts == nil then attempts = 0 end
	if attempts >= 3 then
		Response({lastuser = user}, localization)
	else
		if code == authen_session.data.otp and user == name and string.match(location,"%c") == nil then
			ngx.log(ngx.ALERT,"success login, "..user.." from "..ngx.var.remote_addr)
			users:set(authen_session.data.id,user,authen_session.cookie.lifetime,3)
			access_session:start()
				access_session.data.user = user
			access_session:save()
			names_session:start()
				names_session.data.user = user
			names_session:save()
			authen_session:destroy()
                        ngx.redirect(location)
		else
			ngx.log(ngx.ALERT,"failed login, "..user.." from "..ngx.var.remote_addr)
			users:set(authen_session.data.id,user,authen_session.cookie.lifetime,attempts+1) 
			if attempts + 1 == 3 then
				authen_session:destroy()
				Response({lastuser = lastuser, error = localization['err3']}, localization)
			else
				Response({otp = true, error = localization['err4']}, localization)
			end	
		end
	end	

end
end

return Access
