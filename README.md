# DNS-loadbalancer-V2

Dockerized version of my previous DNSLoadbalancing project based on consul, simplifier solution & infrastructure constraints less


## Configure 
Edit [consul_config.json](consul_config.json) file for matching your requirements of platform. 
- Consul token can be generated with 'uuidgen' command.
- Declare as much service as desired in "services part"

Service_registration:    
-	name: service hostname need to be same on each member of service 
-	id: unique id for this service
-	role:  argument for determine server role (master/slave/none)
-	address: service/VIP ip
-	port: service/VIP port
-	check:
  ⦁ address:  http path of service/VIP endpoint (ex: http://IP/status)
  ⦁	interval: interval between checks (5s)


## Build project
Choose your consul & consul-template versions
```
docker build --build-arg consul_version="1.0.6" --build-arg consul_template_version="0.19.4" -t gorinel/dnsloadbalancer:v2 .
```

## Launch project
```
docker run --restart=always -itd -p 80:80 -p 443:443 -p 53:53/udp --name=consul gorinel/dnsloadbalancer:v2
```

## Testing
Connect on each consul server and test these commands:
```
dig +short consul.service.DNS_DOMAIN @127.0.0.1 (should return 1 ip)
dig +short SERVICENAME.service.DNS_DOMAIN @127.0.0.1 (should return 2 ip)
dig +short ACTIVE_DOMAIN_PREFIX.SERVICENAME.service.DNS_DOMAIN @127.0.0.1 (should return the master ip, you can stop consul service on this host, the answer must change to slave ip)
```

## Issue
If you have a port 53 used:
```
systemctl stop systemd-resolved
systemctl disable systemd-resolved
change your /etc/resolv.conf to point to "nameserver 8.8.8.8" for exemple..
```
