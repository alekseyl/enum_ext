FROM ruby:3.0.3-bullseye

WORKDIR /app
#RUN  apt-get update && apt-get -y install lsb-release
##
#RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
#    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
#    apt-get update && apt-get -y install postgresql postgresql-client-12
#
#RUN sh -c 'echo "local   all             all                                     trust" > /etc/postgresql/14/main/pg_hba.conf' && \
#    service postgresql start && \
#    psql -U postgres -c 'CREATE DATABASE "niceql-test"'

RUN  gem install bundler

COPY lib/enum_ext/version.rb /app/lib/enum_ext/version.rb
COPY enum_ext.gemspec /app/
COPY Gemfile_rails_6 /app/Gemfile
COPY Gemfile_rails_6.lock /app/Gemfile.lock
COPY Rakefile /app/
#
RUN bundle install