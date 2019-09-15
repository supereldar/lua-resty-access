# lua-resty-access
**lua-resty-access** - Safe way to public insecure web applications. 

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
    servername domain.local;
    
      location / {
        #REQUIREMENT: resolver and ca certificate directives are needed for external communication.
        resolver 8.8.8.8;
        lua_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
        
        access_by_lua_block {
          local access = require'resty.access'
          local site = access:new()
          
          #Add users one by one who can access this location. To pass authentication provide "username".
          site:permitUser({username="john", email="eldar.beybutov@gmail.com"})
          
          #You can also permit a single email.
          site:permitEmail({email = "john@snow.winter"})
          
          #Or you can permit the whole domain. "*" - works as wildcard here.
          site:permitEmail({email = "*@snow.winter"})
          
          #Launch Authentication module
          site:protect()
          }
       proxy_pass http://domain2.local;
     }
   }
  }
 ``` 
## Optional configuration
If you want to change access time and persistence or cookie name prefix you can use sessionConfig method.
```shell
site:sessionConfig({cookie_prefix = "luarestyaccess_", access_persistent = false , access_time = 3600})
```

If you want to process emails through your own smtp server you can use emailConfig method.
```shell
site:emailConfig({
  mode = "smtp", 
  host= "smtp.gmail.com", 
  port = 587, 
  tls = true,
  username = "user@gmail.com",
  password = "qwerty123"  
  })
```
