FROM nvidia/cuda-ppc64le:9.2-cudnn7-runtime-ubuntu16.04
LABEL maintainer "Andre Maximo <andmax@gmail.com>"

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends curl wget tar file htop nano vim emacs
RUN apt-get -y clean

RUN curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh | bash -s

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends \
    python3 python3-dev python3-pip python3-setuptools gcc g++ gfortran cmake-curses-gui cmake-gui make \
    numactl libnuma1 libnuma-dev libnccl-dev libffi-dev libgeos-dev qtbase5-dev qt5-default perftest perl \
    libbz2-dev autotools-dev libicu-dev build-essential libboost-dev libboost-serialization-dev \
    pciutils xutils-dev iputils-ping ibverbs-utils debhelper dkms bzip2 hwloc ltrace strace libnccl2 \
    graphviz texlive-xetex gnuplot cuda-samples-9-2 hdf5-tools libhdf5-dev libmunge-dev munge libmunge2
RUN apt-get -y clean

ENV LD_LIBRARY_PATH=/usr/lib/nvidia-410:$LD_LIBRARY_PATH
RUN cd /usr/local/cuda/samples && make -j"$(nproc)" -k &> /dev/null ; exit 0

RUN mkdir -p /var/tmp

ENV OPENMPI_VERS_MAJ=3.1
ENV OPENMPI_VERS=${OPENMPI_VERS_MAJ}.1
RUN wget -q -nc --no-check-certificate -P /var/tmp \
    https://www.open-mpi.org/software/ompi/v${OPENMPI_VERS_MAJ}/downloads/openmpi-${OPENMPI_VERS}.tar.bz2
RUN tar -j -x -f /var/tmp/openmpi-${OPENMPI_VERS}.tar.bz2 -C /var/tmp
RUN cd /var/tmp/openmpi-${OPENMPI_VERS} && \
    CC=gcc CXX=g++ F77=gfortran F90=gfortran FC=gfortran \
    ./configure --prefix=/usr/local/openmpi --disable-getpwuid \
    --enable-orterun-prefix-by-default --with-cuda=/usr/local/cuda --with-verbs && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    echo "/usr/local/openmpi/lib" >> /etc/ld.so.conf.d/openmpi.conf && \
    ldconfig
RUN rm -rf /var/tmp/openmpi-${OPENMPI_VERS}.tar.bz2 /var/tmp/openmpi-${OPENMPI_VERS}

ENV LD_LIBRARY_PATH=/usr/local/openmpi/lib:/usr/lib/powerpc64le-linux-gnu:$LD_LIBRARY_PATH \
    PATH=/usr/local/openmpi/bin:$PATH

ENV SLURM_VERSION=20.02.3
RUN mkdir -p /var/spool/slurm/d /var/spool/slurm/ctld /var/run/slurm /var/log/slurm
RUN wget -q -nc --no-check-certificate -P /var/tmp https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
RUN tar -j -x -f /var/tmp/slurm-${SLURM_VERSION}.tar.bz2 -C /var/tmp
RUN cd /var/tmp/slurm-${SLURM_VERSION} && ./configure --with-munge=/usr/lib/libmunge.so && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install
RUN rm -rf /var/tmp/slurm-${SLURM_VERSION}.tar.bz2 /var/tmp/slurm-${SLURM_VERSION}

RUN apt-get -y autoremove
RUN apt-get -y autoclean
RUN pip3 install --upgrade pip
RUN pip3 install sockets numpy mpi4py ipython ipyparallel jupyter

RUN mkdir -p /workspace
COPY mpi_bw.c /workspace
RUN mpicc -o /workspace/mpi_bw /workspace/mpi_bw.c

ADD AppDef.json /etc/NAE/AppDef.json
RUN wget --post-file=/etc/NAE/AppDef.json --no-verbose https://api.jarvice.com/jarvice/validate -O -

EXPOSE 22
