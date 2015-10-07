FROM ubuntu

RUN apt-get update -y && apt-get install -y jq

ADD bin/check /opt/resource/check
ADD bin/in /opt/resource/in
ADD bin/out /opt/resource/out
