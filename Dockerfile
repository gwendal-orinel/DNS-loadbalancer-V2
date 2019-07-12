FROM ubuntu:18.04
ENTRYPOINT /consul/Entrypoint.sh

WORKDIR /consul

ARG consul_version
ARG consul_template_version

RUN apt-get update -y && apt-get install -y wget unzip curl jq iproute2

RUN wget -O /tmp/consul.zip https://releases.hashicorp.com/consul/"$consul_version"/consul_"$consul_version"_linux_amd64.zip
RUN wget -O /tmp/consul_template.zip  https://releases.hashicorp.com/consul-template/"$consul_template_version"/consul-template_"$consul_template_version"_linux_amd64.zip
RUN unzip /tmp/consul.zip -d /bin && unzip /tmp/consul_template.zip -d /bin


RUN mkdir -p /consul /var/consul/services /var/consul/data /var/consul/templates

COPY . /consul

RUN chmod +x /consul/Entrypoint.sh
