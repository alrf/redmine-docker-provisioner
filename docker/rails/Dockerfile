FROM alrf/ubuntu-rvm-rails

RUN apt -y install libmysqlclient-dev

RUN useradd -d /home/redmine -m -s /bin/bash redmine; \
  adduser redmine sudo; \
  echo 'redmine ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/redmine

USER redmine

RUN mkdir /home/redmine/src

USER root

VOLUME /home/redmine/src

COPY docker-entrypoint.sh /
RUN /bin/chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3000
