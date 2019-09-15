# lua-resty-access
**lua-resty-access** - Authentication controller. 

## Installation
```Shell
$ opm get supereldar/lua-resty-access
```
## Requirements and Quick Start example
Your nginx configuration should look like this 
```nginx
http {
#module require shared dictionaty, please setup this one
  **lua_shared_dict luarestyaccess 10m;**
    server {
    listen 80;
    servername domain.local;
    
      location / {
        #resolver and ca certificate directives are needed for communication.
        **resolver 8.8.8.8;**
        **lua_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;**
        access_by_lua_block {
          **local access = require'resty.access'**
          **local site = access:new()**
          --Add users one by one who can access this location. To pass authentication provide "username".
          **site:permitUser({username="john", email="eldar.beybutov@gmail.com"})**
          --You can also permit a single email.
          **site:permitEmail({email = "john@snow.winter"})**
          --Or you can permit the whole domain. "*" - works as wildcard here.
          **site:permitEmail({email = "*@snow.winter"})**
          --Launch Authentication module
          **site:protect()**
          }
          proxy_pass http://domain2.local;
     }
   }
  }
 ``` 
## Optional configuration
There are two other methods available: sessionConfig and emailConfig.
Setup access time, cookie persistent and cookie name prefix.
```shell
site:sessionConfig({cookie_prefix = "luarestyaccess_", access_persistent = false , access_time = 3600})
```
Setup custom smtp server
Setup access time, cookie persistent and cookie name prefix.
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
