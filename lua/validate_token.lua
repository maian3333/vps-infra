local res = ngx.location.capture("/auth", {
    method = ngx.HTTP_POST,
    body = "token=" .. ngx.var.arg_token
})

if res.status == 200 then
    -- Token is valid
    return ngx.OK
else
    -- Token is invalid
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end
