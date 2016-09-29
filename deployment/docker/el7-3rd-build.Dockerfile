FROM centos:7
WORKDIR /var/tmp
ENTRYPOINT ["/sbin/init"]
RUN yum install -y epel-release upstart
RUN yum groupinstall -y "Development Tools"
RUN yum install -y rpmdevtools
RUN mkdir /var/tmp/openvnet