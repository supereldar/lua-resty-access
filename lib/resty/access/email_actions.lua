local M = {}
local mail = require 'resty.mail'
local http = require 'resty.http'
local cjson = require 'cjson.safe'

local function validemail(str)
  if str == nil then return nil end
  if (type(str) ~= 'string') then
    error("Expected string")
    return nil
  end
  local lastAt = str:find("[^%@]+$")
  local localPart = str:sub(1, (lastAt - 2)) -- Returns the substring before '@' symbol
  local domainPart = str:sub(lastAt, #str) -- Returns the substring after '@' symbol
  -- we werent able to split the email properly
  if localPart == nil then
    return nil, "Local name is invalid"
  end

  if domainPart == nil then
    return nil, "Domain is invalid"
  end
  -- local part is maxed at 64 characters
  if #localPart > 64 then
    return nil, "Local name must be less than 64 characters"
  end
  -- domains are maxed at 253 characters
  if #domainPart > 253 then
    return nil, "Domain must be less than 253 characters"
  end
  -- somthing is wrong
  if lastAt >= 65 then
    return nil, "Invalid @ symbol usage"
  end
  -- quotes are only allowed at the beginning of a the local name
  local quotes = localPart:find("[\"]")
  if type(quotes) == 'number' and quotes > 1 then
    return nil, "Invalid usage of quotes"
  end
  -- no @ symbols allowed outside quotes
  if localPart:find("%@+") and quotes == nil then
    return nil, "Invalid @ symbol usage in local part"
  end
  -- no dot found in domain name
  if not domainPart:find("%.") then
    return nil, "No TLD found in domain"
  end
  -- only 1 period in succession allowed
  if domainPart:find("%.%.") then
    return nil, "Too many periods in domain"
  end
  if localPart:find("%.%.") then
    return nil, "Too many periods in local part"
  end
  -- just a general match
  if not str:match('[%w]*[%p]*%@+[%w]*[%.]?[%w]*') then
    return nil, "Email pattern test failed"
  end
  -- all our tests passed, so we are ok
  return true
end


local function return_error(message,err)
	if not err then err = " " end
	ngx.log(ngx.ERR, message, err)
	return false
end



local function sendmail(to,otp,host,config)
	local host = host:gsub('<', '&#x3C;')
        host = host:gsub('>', '&#x3E;')
  	if not validemail(to) then return return_error("email validation error: ",to) end       
	if not tonumber(otp) and string.len(otp) < 10 then return return_error("otp validation error: ",otp) end
	if config["mode"] == "default" then
		local body = {}
		body['to']=to
		body['otp']=otp
		body['host']=host
		local httpc = http.new()
		local res, err = httpc:request_uri("https://mail.service.luarestyaccess.site:443/", {
			method = "POST",
			path = "/",
			body = cjson.encode(body),
			ssl_verify = true,
          		headers = {
              			["Host"] = "mail.service.luarestyaccess.site",
				["luarestyaccesstoken"] = "623q4hR325t36VsCD3g567922IC0073T",
				["Content-type"] = "application/json",
				["Connection"] = "close"	
          		}
		})	
		if err then return return_error("error send email: ", err) end
		if res.status ~= 200 then return return_error("error send https request to mail.service.luarestyaccess.site: ", err) end
		return true
	end

	if config["mode"] == "smtp" then
		local mailer, err = mail.new({
			host = config['host'],
			port = config['port'],
			starttls = config['starttls'], 
			username = config ['username'], 
			password = config ['password'] 
		})
        	if err then return_error("mail.new error: ", err) end

		local text = "Click the link below to finish your login to"..host.."\r\nhttps://"..host.."?code="..otp.." \r\n"
		text = text.."You can also Copy and paste the code below into the login screen\r\n"..otp.."\r\nThis code will expire in 1 minute."
		local html = "Click the link below to finish your login to"..host.."<br><a href='https://"..host.."?code="..otp.."'>https://"..host.."?code="..otp.."</a><br>" 
		html = html.."Copy and paste the code below into the login screen<br><h2>"..otp.."</h2><br>This code will expire in 1 minute."

	        local ok, err = mailer:send({
			from = "lua-resty-access <"..config ['username']..">",
			to = { to },
			subject = "Login code for "..host.." ",
			text = text,
			html = html
	        })
        	if err then return return_error("mailer:send error: ", err) end
		if ok then return true end
	end
end


M.send = sendmail
M.check = validemail
return M
