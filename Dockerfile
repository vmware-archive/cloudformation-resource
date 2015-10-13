FROM ubuntu

ENV buildDependencies ""
ENV runDependencies python-pip jq

RUN \
    # Installing build dependencies and run dependencies
    apt-get update -yqq \
&&  apt-get install -fyqq ${buildDependencies} ${runDependencies} \
    # Removing build dependencies, clean temporary files
&&  apt-get purge -yqq ${buildDependencies} \
&&  apt-get autoremove -yqq \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip install awscli

ADD bin/check /opt/resource/check
ADD bin/in /opt/resource/in
ADD bin/out /opt/resource/out
