Response = {}
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
local function Response(obj, localization)
	local object = obj or {}
        ngx.header.content_type = "text/html"
	local host = htmlescape(ngx.req.get_headers()["Host"])
	local lastuser = htmlescape(object.lastuser) or ""
        local error = object.error or false
        local otp = object.otp or false
	local user_page = object.user_page or false
	local user = object.user or false
	if user_page == true then
		local body = "Greetings, "..user
		local handle = io.popen("sudo iptables -L | grep luarestyaccess: | grep "..ngx.var.remote_addr)
		local result = handle:read("*a")
		handle:close()
		if result == nil or result == "" then
			body = body.."<br>Your IP is not whitelisted</br>"
			body = body..'<form action="" method="post"><button name="user_actions" value="iptables_add"/>Temporary whitelist my IP</button></form>'
		else
			body = body.."<br>Your IP is whitelisted</br>"
			body = body..'<form action="" method="post"><button name="user_actions" value="iptables_del"/>Delete my IP from whitelist</button></form>'
		end 
		body = body..'<form action="" method="post"><button name="user_actions" value="logout"/>Terminate Session</button></form>'
		ngx.say(body)
		ngx.exit(200)
		return true
	end

	local body = [[
<!DOCTYPE html>
<html>
<head>
<script src="//cdnjs.cloudflare.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
<link href="//maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">
<script src="//maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js#6470E394CBF6DAB6A91682CC8585059B"></script>
<meta name="viewport" content="initial-scale=1" />
<meta charset="UTF-8"> 
</head>
<body>
<div class="container">
        <div class="row justify-content-center align-items-center" style="height:100vh">
            <div class="col-4" style="max-width: 100%">
                <div class="card">
                    <div class="card-body">]]
	body = string.format('%s<h4 style="text-align: center;">%s</h4>', body, localization['title1'])
	if error then 
		body = body..'<label><h4><font color="red">'..error..'</font></h4></label>' 
	end
	if not otp then 
		body = string.format('%s<label>%s <b>%s</b> %s</label><label>%s</label>', body, localization['text1'], host, localization['text2'], localization['text3'])
	else
		body = string.format('%s<label>%s <b2>%s</b2> %s </label><label>%s</label>', body, localization['text4'], host, localization['text5'], localization['text6'])
	end
	body = body..'<form action="" method="post" id="Form">\n'
	if not otp then
		body = string.format('%s<input name="user" type="text" class="form-control" value="%s" style="text-align: center;" placeholder="%s">', body, lastuser, localization['placeholder'])
	else
		body = string.format('%s<input name="code" type="text" id="code" class="form-control" maxlength="6" autocomplete="off" placeholder="000000" style="text-align: center;">', body)
	end
	body = body..'<div class="form-group"></div>'
    if not otp then 
		body = string.format('%s<button onClick="javascript: document.getElementById(\'Form\').submit()" style="width: 100%%" type="button" class="btn btn-primary">%s</a>', body, localization['btn1'])
	else
		body = string.format('%s<button onClick="javascript: document.getElementById(\'Form\').submit()" style="width: 100%%" type="button" class="btn btn-primary">%s</button><input name="name" type="hidden" value="%s"></form><br>', body, localization['btn2'], lastuser)
		body = string.format('%s<form action="" method="post" id="Resend"><input name="user" type="hidden" value="%s">', body, lastuser)
		body = string.format('%s<button onClick="javascript: document.getElementById(\'Resend\').submit();" style="width: 40%%; display: inline; float: right;" type="button" class="btn btn-secondary btn-sm">%s</button></form>', body, localization['btn3'])
		body = string.format('%s<form action="" method="get" id="Back"><button onClick="javascript: document.getElementById(\'Back\').submit();" style="width: 40%%; display: inline; float: left;" type="button" class="btn btn-secondary btn-sm">%s</button></form>', body, localization['btn4'])
	end
        body = body..[[</form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>]]
	ngx.say(body)
	ngx.exit(200)
	return true
end
return Response
