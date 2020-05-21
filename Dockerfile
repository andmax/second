FROM jarvice/ubuntu-cuda-ppc64le:bionic

RUN apt-get -y update
RUN apt-get -y install htop python3 python3-pip
RUN apt-get -y clean

RUN pip3 install --upgrade pip
RUN pip3 install sockets numpy jupyter
RUN pip3 install ipython ipyparallel

EXPOSE 22

ADD AppDef.json /etc/NAE/AppDef.json
RUN wget --post-file=/etc/NAE/AppDef.json --no-verbose https://api.jarvice.com/jarvice/validate -O -

CMD export IPYTHONDIR=/data/andmax/.ipython
CMD export JUPYTER_CONFIG_DIR=/data/andmax/.jupyter
#CMD ipython profile create --parallel
#CMD ipcluster start
CMD jupyter notebook --ip=* --port 9004
