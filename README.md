# lua-resty-access
**lua-resty-access** - Authentication controller. 

## Installation
```Shell
$ opm get supereldar/lua-resty-access
```
## Requirements 
Your nginx configuration should contain next directives 
```Shell
http {
  lua_shared_dict luarestyaccess 10m;
    server {
      location / {
        resolver 8.8.8.8;
        lua_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
        access_by_lua_block {
          local access = require'resty.access'
          local site = access:new()
          --Add users one by one who can access this location.
          site:permitUser({username="john", account="eldar.beybutov@gmail.com"})
          --You can also permit email
          site:protect()
          proxy_pass URL ;
  }

        
