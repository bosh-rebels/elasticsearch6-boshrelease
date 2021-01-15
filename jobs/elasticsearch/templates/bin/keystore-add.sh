#!/bin/bash
set -e
source /var/vcap/packages/openjdk-11/bosh/runtime.env
export PATH=$PATH:/var/vcap/packages/elasticsearch/bin

rm -f /var/vcap/packages/elasticsearch/config/elasticsearch.keystore
<% if_p('elasticsearch.secure_settings') do |secure_settings| %>
echo "== Configure secure settings =="
<% secure_settings.each do |setting| %>
echo "<%= setting['command'] %>: <%= setting['name'] %>"
<% if setting['command'] == 'add' then %>
echo "<%= setting['value'] %>" | elasticsearch-keystore add -xf  <%= setting['name'] %>
<% elsif setting['command'] == 'add-file'  %>
elasticsearch-keystore add-file -f <%= setting['name'] %> <%= setting['value'] %>
<% elsif setting['command'] == 'remove'  %>
elasticsearch-keystore remove <%= setting['name'] %> || true
<% end %>
<% end %>
echo "== Secure settings =="
cp /var/vcap/packages/elasticsearch/config/elasticsearch.keystore /var/vcap/jobs/elasticsearch/config/elasticsearch.keystore
elasticsearch-keystore list || true
<% end %>
