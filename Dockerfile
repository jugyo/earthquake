# Based on the Fedora image
FROM fedora

MAINTAINER "Maciej Lasyk" <maciek@lasyk.info>

# install main packages:
RUN yum -y update
RUN yum -y install openssl-devel openssl readline readline-devel gcc gcc-c++ rubygems rubygems-devel ruby ruby-devel

# install earthquake
RUN gem install earthquake

# set the env:
RUN useradd -d /home/twitter twitter
USER twitter 
ENV HOME /home/twitter
WORKDIR /home/twitter

CMD ["earthquake"]
