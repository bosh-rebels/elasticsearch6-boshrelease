#!/bin/bash

<% if not spec.bootstrap %>
exit 0
<% end %>

<%
  link = link("elasticsearch")     
  
  protocol = link.p('elasticsearch.client.protocol')
  username = link.p('elasticsearch.client.username')
  password = link.p('elasticsearch.client.password')
  host = link.instances[0].address
  port = link.p('elasticsearch.client.port')
  
  elasticsearch_url = "#{protocol}://#{username}:#{password}@#{host}:#{port}"
%>

# If a command fails, exit immediately
set -e

curl -D /dev/stderr -k -s -X PUT "<%= elasticsearch_url %>/_snapshot/<%= p('elasticsearch.snapshots.repository') %>?pretty" \
  -X PUT -H "Content-Type: application/json" \
  -d '{"type": "<%= p('elasticsearch.snapshots.type') %>", "settings": <%= p('elasticsearch.snapshots.settings').to_json %>}' \

curl -D /dev/stderr -k -s -X PUT "<%= elasticsearch_url %>/_snapshot/<%= p('elasticsearch.snapshots.repository') %>/$(date +%Y-%m-%d_%H-%M-%S_%Z | tr "[:upper:]" "[:lower:]")?wait_for_completion=true&pretty"
