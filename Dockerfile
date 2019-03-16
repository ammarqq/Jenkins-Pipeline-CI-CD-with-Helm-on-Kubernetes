FROM ubuntu:16.04
MAINTAINER ammarqqqq

RUN apt-get -y update \ 
        && apt-get clean all \
        && apt-get install -y nginx iproute

EXPOSE 80
COPY index.html /usr/share/nginx/html/
CMD ["nginx", "-g", "daemon off;"]
