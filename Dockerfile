# Based on the Fedora image
FROM ruby:2.4.2

RUN apt-get update
RUN apt-get install -y libssl-dev git locales locales-all
ENV LANG C.UTF-8

RUN gem install bundler
RUN gem install earthquake -v 1.0.2

WORKDIR /root/earthquake
COPY . .
RUN bundle install
RUN cp /usr/local/bundle/gems/earthquake-1.0.2/consumer.yml ./
ARG TZ
ENV TZ ${TZ:-UTC}
ENTRYPOINT ["bundle", "exec", "ruby", "./bin/earthquake"]
