FROM ubuntu:xenial

# Update the package list
RUN apt-get update

# add add-apt-repository command
RUN apt-get install -y software-properties-common

# Add Sphinx PPA repository
RUN add-apt-repository ppa:builds/sphinxsearch-rel22

# Install sphinx
RUN apt-get update && apt-get install -y sphinxsearch

# Start sphinx service
RUN service sphinxsearch start