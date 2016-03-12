FROM ubuntu:trusty

RUN true \
  && apt-get -q update \
  && apt-get -qy install python-pip wget \
  && apt-get -q purge \
  && apt-get -q autoremove \
  && apt-get -q clean \
  && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && pip install awscli \
  && wget -qO /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
  && chmod +x /usr/bin/jq

ADD bin/* /opt/resource/
