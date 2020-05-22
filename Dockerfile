FROM jarvice/ubuntu-cuda-ppc64le:bionic

RUN apt-get -y update
RUN apt-get -y install curl htop python3 python3-pip
RUN apt-get -y clean

ENV MPI_VERSION 2.0.1

RUN curl -H 'Cache-Control: no-cache' \
        https://raw.githubusercontent.com/nimbix/base-ubuntu-openmpi/master/install.sh \
            | bash -s

RUN pip3 install --upgrade pip
RUN pip3 install sockets numpy jupyter
RUN pip3 install ipython ipyparallel
RUN pip3 install mpi4py

EXPOSE 22

ADD AppDef.json /etc/NAE/AppDef.json
RUN wget --post-file=/etc/NAE/AppDef.json --no-verbose https://api.jarvice.com/jarvice/validate -O -
