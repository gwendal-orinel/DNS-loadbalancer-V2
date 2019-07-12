#!/bin/bash

IP=$(ip -4 -o a | sed -e '/^2:/!d;s/^.*inet //;s/\/.*$//g')

config="$(cat consul_config.json)"

master_token=$(echo $config | jq -r .master_token)
datacenter=$(echo $config | jq -r .datacenter)
dns_domain=$(echo $config | jq -r .dns_domain)
active_domain_prefix=$(echo $config | jq -r .active_domain_prefix)
port_http=$(echo $config | jq -r .ports.http)
port_https=$(echo $config | jq -r .ports.https)
port_dns=$(echo $config | jq -r .ports.dns)


cp templates/config* /var/consul/
cp templates/ha.tmp /var/consul/templates/

sed -i -e "s/{{ ip_add }}/$IP/g" /var/consul/config.json
sed -i -e "s/{{ item.datacenter }}/$datacenter/g" /var/consul/config.json
sed -i -e "s/{{ item.dns_domain }}/$dns_domain/g" /var/consul/config.json
sed -i -e "s/{{ item.master_token }}/$master_token/g" /var/consul/config.json /var/consul/config-template.hcl /var/consul/templates/ha.tmp
sed -i -e "s/{{ item.port.http }}/$port_http/g" /var/consul/config.json
sed -i -e "s/{{ item.port.https }}/$port_https/g" /var/consul/config.json
sed -i -e "s/{{ item.port.dns }}/$port_dns/g" /var/consul/config.json
sed -i -e "s/{{ item.active_domain_prefix }}/$active_domain_prefix/g" /var/consul/templates/ha.tmp

exec consul agent -syslog=false --config-file /var/consul/config.json &

sleep 5

curl -X PUT -d '{ "ID": "anonymous","Type": "client","Rules": "node \"\" { policy = \"read\" } service \"\" { policy = \"read\" }" }' http://127.0.0.1:"$port_http"/v1/acl/update?token="$master_token"

for service in $(echo $config | jq -c .services[]); do

        id=$(echo $service | jq -r .id)
        name=$(echo $service | jq -r .name)
        address=$(echo $service | jq -r .address)
        port=$(echo $service | jq .port)
        role=$(echo $service | jq -r .role)
        check_http=$(echo $service | jq -r .check.address)
        check_interval=$(echo $service | jq -r .check.interval)
	src="templates/service.json"

	## classic mode
	if [[ $role == "master" ]]; then tags='["master","'$active_domain_prefix'"]' ;else if [[ $role == "slave" ]]; then tags='["slave"]' ; else tags='[""]' ;fi ;fi
        dest="/var/consul/services/$id.json"
        cp $src $dest
        sed -i -e "s/{{ item.id }}/$id/g" $dest
        sed -i -e "s/{{ item.name }}/$name/g" $dest
        sed -i -e "s/{{ item.address }}/$address/g" $dest
        sed -i -e "s/{{ item.port }}/$port/g" $dest
        sed -i -e "s/{{ item.tags }}/$tags/g" $dest
        sed -i -e "s#{{ item.check.address }}#$check_http#g" $dest
        sed -i -e "s/{{ item.check.interval }}/$check_interval/g" $dest

        ##ha mode
	if [[ $role == "master" ]]; then tags='["master"]' ;else if [[ $role == "slave" ]]; then tags='["slave","'$active_domain_prefix'"]' ; else tags='[""]' ;fi ;fi
        dest="/var/consul/services/"$id"_ha.json"
        cp $src $dest
        sed -i -e "s/{{ item.id }}/$id/g" $dest
        sed -i -e "s/{{ item.name }}/$name/g" $dest
        sed -i -e "s/{{ item.address }}/$address/g" $dest
        sed -i -e "s/{{ item.port }}/$port/g" $dest
        sed -i -e "s/{{ item.tags }}/$tags/g" $dest
        sed -i -e "s#{{ item.check.address }}#$check_http#g" $dest
        sed -i -e "s/{{ item.check.interval }}/$check_interval/g" $dest


	##service registration
	curl -X PUT -d @/var/consul/services/$id.json http://127.0.0.1:$port_http/v1/agent/service/register?token=$master_token

done

exec consul-template -config "/var/consul/config-template.hcl" &

exec consul monitor -http-addr=http://127.0.0.1:$port_http -token=$master_token 
