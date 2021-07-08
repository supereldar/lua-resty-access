local M = {}
local mail = require 'resty.mail'
local http = require 'resty.http'
local cjson = require 'cjson.safe'
local str = require 'resty.string'

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

local function htmlescape(string)
        if not string then local string = false end
        if string then
                string = string:gsub("<", "&lt;")
                string = string:gsub(">", "&gt;")
                string = string:gsub("'", "&quot;")
                string = string:gsub('"', "&quot;")
                string = string:gsub("&", "&amp;")
        end
        return string
end

local function sendemail(to,otp,host,location,config,localization)
        local ok = true
        local host = htmlescape(host)
	local location = htmlescape(location)
	location = location:gsub("#","")
        if not validemail(to) then ok = return_error("email validation error: ",to) end
        if not tonumber(otp) or string.len(otp) > 10 then ok = return_error("otp validation error: ",otp) end
        
        if ok and config["mode"] == "default" then
                local body = {}
                body['to'] = to
                body['otp'] = otp
                body['host'] = host
                body['location'] = location
                local httpc = http.new()
                local res, err = httpc:request_uri("https://mail.service.luarestyaccess.site:443/", {
                        method = "POST",
                        path = "/",
                        body = cjson.encode(body),
                        ssl_verify= true,
                        headers = {
                                ["Host"] = "mail.service.luarestyaccess.site",
                                ["luarestyaccesstoken"] = "623q4hR325t36VsCD3g567922IC0073T",
                                ["Content-type"] = "application/json",
                                ["Connection"] = "close"
                        }
                })
                if err then ok = return_error("error send email: ", err) end
                if res.status ~= 200 then ok = return_error("error send https request to mail.service.luarestyaccess.site. Reposnse code is ", res.status) end
        end

        if ok and config["mode"] == "smtp" then
                local mailer, err = mail.new({
                        host = config['host'],
                        port = config['port'],
                        starttls = config['starttls'],
                        username = config['username'],
                        password = config['password'],
                        domain = config['domain']
                })
                if err then ok = return_error("mail.new error: ", err) end
                local url = "https://"..host..location
                local uri = url.."#code="..otp

                local text = string.format("%s %s\r\n%s\r\n %s \r\n%s", localization['mail1'], host, localization['mail2'], otp, localization['mail3'])

                local html = string.format("%s %s<br>%s<br><h2>%s</h2> %s", localization['mail1'], host, localization['mail2'], otp, localization['mail3'])

				local from_header = config['from']
				if config['username'] then from_header = config['username'] end
                local success, err = mailer:send({
                        from = "lua-resty-access <"..from_header..">",
                        to = { to },
                        subject = string.format("%s %s : %s", localization['mail4'], host, otp),
                        text = text,
                        html = html
                })
                if err then ok = return_error("mailer:send error: ", err) end
        end

        return ok

end
M.check = validemail
M.send = sendemail
return M
