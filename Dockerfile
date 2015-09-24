FROM phusion/baseimage

RUN groupadd -r kibana && useradd -r -g kibana kibana

RUN apt-get update && apt-get install -y ca-certificates curl wget --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN arch="$(dpkg --print-architecture)" \
	&& set -x \
	&& curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch" \
	&& curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch.asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu

# Download and install consul-template
ENV CONSUL_TEMPLATE_VERSION=0.10.0

RUN ( wget --no-check-certificate \
https://github.com/hashicorp/consul-template/releases/download/v${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.tar.gz \
-O /tmp/consul_template.tar.gz && \
gunzip /tmp/consul_template.tar.gz && \
cd /tmp && \
tar xf /tmp/consul_template.tar && \
cd /tmp/consul-template* && \
mv consul-template /usr/bin && \
rm -rf /tmp/* )

ENV KIBANA_VERSION 4.1.2
ENV KIBANA_SHA1 45e67114f7dac4ccac8118bf98ee8f6362c7a6a1

RUN set -x \
	&& curl -fSL "https://download.elastic.co/kibana/kibana/kibana-${KIBANA_VERSION}-linux-x64.tar.gz" -o kibana.tar.gz \
	&& echo "${KIBANA_SHA1}  kibana.tar.gz" | sha1sum -c - \
	&& mkdir -p /opt/kibana \
	&& tar -xz --strip-components=1 -C /opt/kibana -f kibana.tar.gz \
	&& rm kibana.tar.gz

ENV PATH /opt/kibana/bin:$PATH

# Set up 
ADD mesos/consul_startup.json /opt/kibana/

RUN mkdir /var/log/kibana/
# Set up for init system to start processes
RUN mkdir /etc/service/consul-template /etc/service/kibana

# Consul-template will create the run script for kibana
ADD mesos/run.sh.ctmpl /opt/kibana/
ADD mesos/start_consul_template.sh /etc/service/consul-template/run
RUN chmod 777 /etc/service/consul-template/run

# Use baseimage-docker's init process.
WORKDIR /opt/kibana
CMD ["/sbin/my_init"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EXPOSE 5601
