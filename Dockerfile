FROM ubuntu:bionic

RUN apt-get update
RUN apt-get install -y \
  build-essential \
  libcairo2 \
  libffi-dev \
  libgdk-pixbuf2.0-0 \
  liblzma-dev \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  patch \
  python3 \
  python3-cffi \
  python3-dev \
  python3-pip \
  python3-setuptools \
  python3-wheel \
  shared-mime-info \
  software-properties-common \
  zlib1g-dev
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update
RUN apt-get install -y ruby2.5 ruby2.5-dev
RUN gem install bundler

COPY . /docs-converter
WORKDIR /docs-converter

RUN bundle install
RUN bundle exec rspec

