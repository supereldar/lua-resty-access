# lua-resty-access
**lua-resty-access** - Web application access management module based on passwordless authentication for OpenResty.

## Installation
```Shell
$ opm get supereldar/lua-resty-access
```
## Requirements and Quick Start example
Your nginx configuration should look like this 
```nginx
http {

#REQUIREMENT: module require temporary storage, please setup luarestyaccess dictionary.
    lua_shared_dict luarestyaccess 10m;
  
    server {
    listen 80;
    server_name domain.local;
    location / {
      
#REQUIREMENT: resolver and ca certificate directives are needed for external communication.
        resolver 8.8.8.8;
        lua_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;

#REQUIREMENT: Call method Protect of resty.access object using access_by_lua* directive to activate access restriction.
        access_by_lua_block {
          local access = require'resty.access'
          local site = access:new()
           
#Add email addresses whose owners are permit to enter this server or location. Provide this email in auth form to get your code.
          site:permitEmail({email = "john@snow.winter"})
          
#Or you can permit the whole domain. "*" - works as wildcard here (works in other cases too, like "teamA.*@gmail.com").
          site:permitEmail({email = "*@snow.winter"})
          
#If you want to prevent email enumeration you can setup username based authentication. Provide username in auth form to get code on related email address.
          site:permitUser({username="john", email="john@snow.winter"})
#Specify smtp server.
          site:emailConfig({
                mode = "smtp", 
                host= "smtp.gmail.com", 
                port = 587, 
                tls = true,
                username = "user@gmail.com",
                password = "qwerty123"  
           })
#Launch module
          site:protect()
         }

       proxy_pass http://app1.domain.local;
     }
   }
}
``` 
## Optional configuration
If you want to change access time, authentication code wait time, persistence or cookie name prefix you can use sessionConfig method.
```shell
site:sessionConfig({cookie_prefix = "luarestyaccess_", access_persistent = false , access_time = 3600, auth_cookie_lifetime = 60})
```
If you want to keep users authenticated after configuration reload, specify static secret using access_secret key.
```shell
site:sessionConfig({access_secret = "623q4hR325t36VsCD3g567922IC0073T"})
```
If you want grant access to the whole domain specify it's name using cookie_domain key.
```shell
site:sessionConfig({cookie_domain = "domain.local"})
```
If your smtp server does not support TLS, use these parameters instead:
 ```      site:emailConfig({
                mode = "smtp", 
                host = "mail.yourdomain.com",
                port = 25,
                domain = "yourdomain.com",
                from = "ptaf@yourdomain.com"
          })
```
if you want customize webpage and email text you can use this template(localization support).
```       site:localization({
                title1 = "Access restricted",
                text1 = "To enter",
                text2 = "please confirm your right to do so.",
                text3 = "Get a login code sent to you:",
                text4 = "A code for",
                text5 = "has been sent to you.",
                text6 = "Enter it below to complete your login:",
                placeholder = "type your username/email",
                btn1 = "Let me in!",
                btn2 = "Access",
                btn3 = "Re-send Code",
                btn4 = "Back",
                mail1 = "Finish your login to ",
                mail2 = "Copy and paste the code below into the login screen",
                mail3 = "This code will expire in 1 minute.",
                mail4 = "Login code for",
                err1 = "You are not welcome here",
                err2 = "Problem with sending email",
                err3 = "Get yourself a new one.",
                err4 = "Code is wrong."
          })
 ```
