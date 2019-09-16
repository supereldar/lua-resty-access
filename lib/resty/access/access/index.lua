Response = {}
function Response(obj)
	local object = obj or {}
        ngx.header.content_type = "text/html"
	local host = ngx.req.get_headers()["Host"]
	local lastuser = object.lastuser or "" 
        local error = object.error or false
        local otp = object.otp or false
	local body = [[
<!DOCTYPE html>
<html>
<head>
<script src="//cdnjs.cloudflare.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
<link href="//maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">
<script src="//maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"></script>
</head>
<body>
<div class="container">
        <div class="row justify-content-center align-items-center" style="height:100vh">
            <div class="col-4">
                <div class="card">
                    <div class="card-body">
			<h4 style="text-align: center;">Access restricted</h4>]]
	if error then 
		body = body..'<label><h4><font color="red">'..error..'</font></h4></label>' 
	end
	if not otp then 
		body = body..'<label>To enter <b>'..host..'</b> please confirm your right to do so.</label><label>Get a login code sent to you:</label>'
	else
		body = body..'<label>A code for <b2>'..host..'</b2>  has been sent to you. </label><label>Enter it below to complete your login:</label>'
	end
	body = body..'<form action="" method="post" id="Form">\n'
	if not otp then
		body = body..'<input name="user" type="text" class="form-control" value="'..lastuser..'" style="text-align: center;" placeholder="type your username/email">'
	else
		body = body..'<input name="code" type="text" id="code" class="form-control" autocomplete="off" placeholder="000000" style="text-align: center;">'
	end
	body = body..'<div class="form-group"></div>'
        if not otp then 
		body = body..'<button onClick="javascript: document.getElementById(\'Form\').submit()" style="width: 100%" type="button" class="btn btn-primary">Let me in!</a>'
	else
		body = body..'<button onClick="javascript: document.getElementById(\'Form\').submit()" style="width: 100%" type="button" class="btn btn-primary">Access</button></form><br>'
		body = body..'<form action="" method="post" id="Resend"><input name="user" type="hidden" value="'..lastuser..'">'
		body = body..'<button onClick="javascript: document.getElementById(\'Resend\').submit();" style="width: 40%; display: inline; float: right;" type="button" class="btn btn-secondary btn-sm">Re-send Code</button></form>'
		body = body..'<form action="" method="get" id="Back"><button onClick="javascript: document.getElementById(\'Back\').submit();" style="width: 40%; display: inline; float: left;" type="button" class="btn btn-secondary btn-sm">Back</button></form>'
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

