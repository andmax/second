FROM nvidia/cuda-ppc64le:10.0-cudnn7-runtime-ubuntu18.04
LABEL maintainer="andmax@gmail.com"

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends curl wget tar file htop nano vim emacs
RUN apt-get -y clean

RUN curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh | bash -s

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends pkg-config debhelper dkms build-essential software-properties-common
RUN apt-get install -y --no-install-recommends pciutils iputils-ping apt-utils hwloc ltrace strace ibverbs-utils libnccl2
RUN apt-get install -y --no-install-recommends gcc g++ gfortran perl make cmake-curses-gui cmake-gui autotools-dev
RUN apt-get install -y --no-install-recommends libboost-all-dev xutils-dev qtbase5-dev qt5-default numactl libnuma1 libnuma-dev
RUN apt-get install -y --no-install-recommends libxslt-dev libmunge-dev libxml2-dev libopenblas-dev liblapack-dev
RUN apt-get install -y --no-install-recommends libnccl-dev libffi-dev libgeos-dev libicu-dev libbz2-dev liblz-dev
RUN apt-get install -y --no-install-recommends texlive-xetex libfreetype6-dev gnuplot graphviz perftest
RUN apt-get install -y --no-install-recommends libpng-dev munge libmunge2 hdf5-tools bzip2
RUN apt-get install -y --no-install-recommends --fix-missing cuda-samples-11-0
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

RUN echo "export PATH=/usr/local/openmpi/bin:\$PATH" >> /etc/profile.d/openmpi.sh

ENV LD_LIBRARY_PATH=/usr/local/openmpi/lib:/usr/lib/powerpc64le-linux-gnu:$LD_LIBRARY_PATH \
    PATH=/usr/local/openmpi/bin:$PATH

#ENV SLURM_VERSION=20.02.3
#RUN mkdir -p /var/spool/slurm/d /var/spool/slurm/ctld /var/run/slurm /var/log/slurm
#RUN wget -q -nc --no-check-certificate -P /var/tmp https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
#RUN tar -j -x -f /var/tmp/slurm-${SLURM_VERSION}.tar.bz2 -C /var/tmp
#RUN cd /var/tmp/slurm-${SLURM_VERSION} && ./configure --with-hdf5=no --with-munge=/usr/lib/libmunge.so && \
#    make -j"$(nproc)" && \
#    make -j"$(nproc)" install
#RUN rm -rf /var/tmp/slurm-${SLURM_VERSION}.tar.bz2 /var/tmp/slurm-${SLURM_VERSION}

RUN apt-get -y autoremove
RUN apt-get -y autoclean

RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-ppc64le.sh
RUN bash Anaconda3-2020.02-Linux-ppc64le.sh -b -p /usr/local/anaconda3 -f
ENV PATH /usr/local/anaconda3/bin:$PATH
RUN conda init --system
RUN conda update conda

RUN conda install -c conda-forge boost numpy setuptools mpi4py ipyparallel pygraphml
RUN conda install -c conda-forge pandas matplotlib scipy scikit-learn scikit-image
RUN conda install -c conda-forge six jsonschema ipython ipywidgets jupyter notebook

#RUN conda install -c anaconda tensorflow-gpu

RUN mkdir -p /workspace
COPY mpi_bw.c /workspace
RUN mpicc -o /workspace/mpi_bw /workspace/mpi_bw.c

#RUN echo "/data/inglib/power8/bin" >> /etc/ld.so.conf.d/ibf.conf && ldconfig

#COPY slurm/status_slurm.sh /usr/local/bin/status_slurm.sh
#COPY slurm/start_slurm.sh /usr/local/bin/start_slurm.sh
#COPY slurm/stop_slurm.sh /usr/local/bin/stop_slurm.sh

#COPY slurm/base_slurm.conf /usr/local/etc/base_slurm.conf
#COPY slurm/gres.conf /usr/local/etc/gres.conf

#RUN chmod a+rx /usr/local/bin/status_slurm.sh
#RUN chmod a+rx /usr/local/bin/start_slurm.sh
#RUN chmod a+rx /usr/local/bin/stop_slurm.sh

#RUN echo "export PYTHONPATH=/data/snail/:\$PYTHONPATH" >> /etc/profile.d/pythonpath.sh

ADD AppDef.json /etc/NAE/AppDef.json
RUN wget --post-file=/etc/NAE/AppDef.json --no-verbose https://api.jarvice.com/jarvice/validate -O -

#RUN echo "\
##!/bin/bash\n\
#/data/snail/slurm_nimbix/all_create_user.sh\n\
#/data/snail/slurm_nimbix/all_start_jupyter.sh\n\
#sudo cp /data/snail/IbfPython/IbfExtension/build/lib/python3.7/site-packages/IbfExt* \
#/usr/local/anaconda3/lib/python3.7/site-packages/\n\
#sudo touch /var/log/slurm/accounting.txt\n\
#sudo chmod a+r /var/log/slurm/accounting.txt\n\
#sudo /usr/local/bin/start_slurm.sh" > /usr/local/bin/all_up.sh
#RUN chmod a+rx /usr/local/bin/all_up.sh
#RUN sed -i -e '$i /usr/local/bin/all_up.sh\n' /etc/rc.local

EXPOSE 22
