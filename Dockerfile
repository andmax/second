FROM jarvice/ubuntu-cuda-ppc64le:bionic

RUN apt-get -y update
RUN apt-get -y install htop python3 python3-pip
RUN apt-get -y clean

RUN pip3 install --upgrade pip
RUN pip3 install sockets numpy jupyter
RUN pip3 install ipython ipyparallel

# Expose port 22 for local JARVICE emulation in docker
EXPOSE 22

ADD AppDef.json /etc/NAE/AppDef.json
RUN wget --post-file=/etc/NAE/AppDef.json --no-verbose https://api.jarvice.com/jarvice/validate -O -
