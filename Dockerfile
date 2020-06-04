FROM nvidia/cuda-ppc64le:9.2-cudnn7-runtime-ubuntu16.04
LABEL maintainer "Andre Maximo <andmax@gmail.com>"

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends curl wget htop nano vim emacs
RUN apt-get -y clean

RUN curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh | bash -s

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends python3 python3-dev python3-pip python3-setuptools gcc g++ gfortran perl
RUN apt-get install -y --no-install-recommends numactl libnuma1 libnuma-dev libboost-all-dev cmake-curses-gui cmake-gui make
RUN apt-get install -y --no-install-recommends pciutils xutils-dev iputils-ping ibverbs-utils debhelper dkms bzip2 tar file hwloc
RUN apt-get install -y --no-install-recommends ltrace strace libgeos-dev libnccl2 libnccl-dev libffi-dev graphviz
RUN apt-get install -y --no-install-recommends texlive-xetex gnuplot perftest cuda-samples-9-2 qtbase5-dev qt5-default
RUN apt-get install -y --no-install-recommends hdf5-tools libhdf5-dev libmunge-dev munge libmunge2
RUN apt-get -y clean

RUN cd /usr/local/cuda/samples && make -j32 -k &> /dev/null ; exit 0

ENV OPENMPI_VERS_MAJ=3.1
ENV OPENMPI_VERS=${OPENMPI_VERS_MAJ}.1
RUN mkdir -p /var/tmp
RUN wget -q -nc --no-check-certificate -P \
    /var/tmp https://www.open-mpi.org/software/ompi/v${OPENMPI_VERS_MAJ}/downloads/openmpi-${OPENMPI_VERS}.tar.bz2
RUN tar -x -f /var/tmp/openmpi-${OPENMPI_VERS}.tar.bz2 -C /var/tmp -j
RUN cd /var/tmp/openmpi-${OPENMPI_VERS} && \
    CC=gcc CXX=g++ F77=gfortran F90=gfortran FC=gfortran \
    ./configure --prefix=/usr/local/openmpi --disable-getpwuid \
    --enable-orterun-prefix-by-default --with-cuda=/usr/local/cuda --with-verbs && \
    make -j32 && \
    make -j32 install
RUN rm -rf /var/tmp/openmpi-${OPENMPI_VERS}.tar.bz2 /var/tmp/openmpi-${OPENMPI_VERS}

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib:/usr/local/openmpi/lib:/usr/lib/nvidia-410"
ENV PATH="${PATH}:/usr/local/bin:/usr/local/openmpi/bin"

RUN mkdir -p /workspace
COPY mpi_bw.c /workspace
RUN mpicc -o /workspace/mpi_bw /workspace/mpi_bw.c

ADD AppDef.json /etc/NAE/AppDef.json
RUN wget --post-file=/etc/NAE/AppDef.json --no-verbose https://api.jarvice.com/jarvice/validate -O -

RUN pip3 install --upgrade pip
RUN pip3 install sockets numpy mpi4py ipython ipyparallel jupyter

ENV SLURM_VERSION=20.02.3
RUN mkdir -p /var/tmp
RUN mkdir -p /var/spool/slurm/d /var/spool/slurm/ctld /var/run/slurm /var/log/slurm
RUN wget -q -nc --no-check-certificate -P /var/tmp https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
RUN tar -j -x -f /var/tmp/slurm-${SLURM_VERSION}.tar.bz2 -C /var/tmp
RUN cd /var/tmp/slurm-${SLURM_VERSION} && ./configure --with-munge=/usr/lib/libmunge.so && make -j32 && make -j32 install
RUN rm -rf /var/tmp/slurm-${SLURM_VERSION}.tar.bz2 /var/tmp/slurm-${SLURM_VERSION}

EXPOSE 22
