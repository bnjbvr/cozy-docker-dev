FROM ubuntu:15.04

ENV DEBIAN_FRONTEND noninteractive

# Install Cozy tools and dependencies.
RUN echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu vivid main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C \
 && apt-get update --quiet \
 && apt-get dist-upgrade --yes

 RUN apt-get install --quiet --yes \
  build-essential \
  couchdb \
  curl \
  git \
  imagemagick \
  language-pack-en \
  libffi6 \
  libffi-dev \
  libssl-dev \
  libxml2-dev \
  libxslt1-dev \
  libjpeg-dev \
  lsof \
  nginx \
  openssh-server \
  pwgen \
  python-dev \
  python-pip \
  python-setuptools \
  python-software-properties \
  software-properties-common \
  sqlite3 \
  sudo \
  wget

RUN update-locale LANG=en_US.UTF-8
RUN pip install supervisor virtualenv

# Install NodeJS 4.2.X LTS
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get install -y nodejs

# Install CoffeeScript, Cozy Monitor and Cozy Controller via NPM.
RUN npm install -g \
  coffee-script \
  cozy-controller \
  cozy-monitor

# Create Cozy users, without home directories.
RUN useradd -M cozy \
 && useradd -M cozy-data-system \
 && useradd -M cozy-home \
 && mkdir /etc/cozy \
 && chown -hR cozy /etc/cozy

# Remove couchdb admin login, if existing.
RUN if [ "$(tail -n1 /etc/couchdb/local.ini | awk '{ print $1 }')" != ";admin" ]; then sed -i '$ d' /etc/couchdb/local.ini;	fi

# Configure CouchDB
RUN mkdir /var/run/couchdb \
 && chown -hR couchdb /var/run/couchdb \
 && su - couchdb -c 'couchdb -b' \
 && sleep 2 \
 && while ! curl -s 127.0.0.1:5984; do sleep 1; done

# Configure Supervisor.
ADD supervisor/supervisord.conf /etc/supervisord.conf
RUN mkdir -p /var/log/supervisor \
 && chmod 777 /var/log/supervisor \
 && /usr/local/bin/supervisord -c /etc/supervisord.conf

# Start up background services and install the Cozy platform apps.
ENV NODE_ENV development

RUN su - couchdb -c 'couchdb -b' \
 && sleep 2 \
 && while ! curl -s 127.0.0.1:5984; do sleep 1; done \
 && cozy-controller & sleep 2 \
 && while ! curl -s 127.0.0.1:9002; do sleep 1; done \
 && cozy-monitor install data-system \
 && cozy-monitor install home \
 && cozy-monitor install proxy

# Configure Nginx and check its configuration by restarting the service.
ADD nginx/nginx.conf /etc/nginx/nginx.conf
ADD nginx/cozy /etc/nginx/sites-available/cozy
ADD nginx/cozy-ssl /etc/nginx/sites-available/cozy-ssl
RUN chmod 0644 /etc/nginx/sites-available/cozy /etc/nginx/sites-available/cozy-ssl \
 && rm /etc/nginx/sites-enabled/default \
 && ln -s /etc/nginx/sites-available/cozy /etc/nginx/sites-enabled/cozy
RUN nginx -t

# Install mailcatcher
RUN apt-get install -y build-essential software-properties-common libsqlite3-dev ruby-dev
RUN gem update --system
RUN gem install mailcatcher

# Configure SSH
RUN mkdir /var/run/sshd

RUN mkdir /root/.ssh && \
    chmod 700 /root/.ssh && \
    chown root:root /root/.ssh

# -> Disallow logging in to SSH with a password.
RUN sed -i "s/^.PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config \
 && sed -i "s/^.ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/" /etc/ssh/sshd_config

# Import Supervisor configuration files.
ADD supervisor/cozy-controller.conf /etc/supervisor/conf.d/cozy-controller.conf
ADD supervisor/cozy-init.conf /etc/supervisor/conf.d/cozy-init.conf
ADD supervisor/couchdb.conf /etc/supervisor/conf.d/couchdb.conf
ADD supervisor/nginx.conf /etc/supervisor/conf.d/nginx.conf
ADD supervisor/sshd.conf /etc/supervisor/conf.d/sshd.conf
ADD supervisor/mailcatcher.conf /etc/supervisor/conf.d/mailcatcher.conf
ADD cozy-init /etc/init.d/cozy-init
RUN chmod 0644 /etc/supervisor/conf.d/*

# Clean APT cache for a lighter image.
RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 80/443: web ui
# 5984: couchdb
# 9002: cozy-controller
# 9101: cozy-data-system
# 9104: cozy-proxy
# 8001: mailcatcher web ui
EXPOSE 80 443 5984 9002 9101 9104 8001

VOLUME ["/var/lib/couchdb", "/etc/cozy", "/usr/local/cozy", "/root/.ssh"]

CMD [ "/usr/local/bin/supervisord", "-n", "-c", "/etc/supervisord.conf" ]
