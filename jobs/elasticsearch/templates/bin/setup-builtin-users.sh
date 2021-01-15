#!/bin/bash

exec 2>&1

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

############################################################################

<%
protocol = p('elasticsearch.client.protocol', 'http')
url="#{protocol}://"
username = p('elasticsearch.client.username', nil)
password = p('elasticsearch.client.password', nil)
if username && password
  url += "#{username}:#{password}@"
end
host = spec.address
url += host
port = p('elasticsearch.client.port')
if port
  url += ":#{port}"
end
%>
function request_elk {
    local action=$1
    local endpoint=$2
    local body=$3
    local url=<%= url %>

    curl -s -X "$action" -H 'Content-Type: application/json' -k "${url}${endpoint}" -d "$body" > /dev/null
}

<% p('elasticsearch.security.builtin_users').each do |user_hash| %>
request_elk POST /_security/user/<%="#{user_hash.fetch('name')}"%>/_password '{"password" : "<%= "#{user_hash.fetch('password')}" %>"}'
<% end %>
