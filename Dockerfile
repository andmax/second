FROM nvidia/cuda-ppc64le:9.2-cudnn7-runtime-ubuntu16.04
LABEL maintainer="andmax@gmail.com"

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends curl wget tar file htop nano vim emacs
RUN apt-get -y clean

RUN curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh | bash -s

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends pkg-config debhelper dkms build-essential pciutils iputils-ping apt-utils
RUN apt-get install -y --no-install-recommends ibverbs-utils bzip2 hwloc ltrace strace libnccl2 hdf5-tools munge libmunge2
RUN apt-get install -y --no-install-recommends gcc g++ gfortran perl make cmake-curses-gui cmake-gui autotools-dev
RUN apt-get install -y --no-install-recommends libboost-all-dev xutils-dev qtbase5-dev qt5-default numactl libnuma1
RUN apt-get install -y --no-install-recommends libxslt-dev libmunge-dev libxml2-dev libopenblas-dev liblapack-dev
RUN apt-get install -y --no-install-recommends libnuma-dev libnccl-dev libffi-dev libgeos-dev libicu-dev libbz2-dev
RUN apt-get install -y --no-install-recommends texlive-xetex libfreetype6-dev gnuplot graphviz perftest libpng12-dev 
#RUN apt-get install -y --no-install-recommends python3 python3-dev python3-pip python3-setuptools
RUN apt-get install -y --no-install-recommends --fix-missing cuda-samples-9-2
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

ENV SLURM_VERSION=20.02.3
RUN mkdir -p /var/spool/slurm/d /var/spool/slurm/ctld /var/run/slurm /var/log/slurm
RUN wget -q -nc --no-check-certificate -P /var/tmp https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
RUN tar -j -x -f /var/tmp/slurm-${SLURM_VERSION}.tar.bz2 -C /var/tmp
RUN cd /var/tmp/slurm-${SLURM_VERSION} && ./configure --with-hdf5=no --with-munge=/usr/lib/libmunge.so && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install
RUN rm -rf /var/tmp/slurm-${SLURM_VERSION}.tar.bz2 /var/tmp/slurm-${SLURM_VERSION}

RUN apt-get -y autoremove
RUN apt-get -y autoclean

#RUN pip3 install --upgrade pip setuptools
#RUN pip3 install matplotlib pygraphml scipy pandas numpy \
#    mpi4py sockets ipython ipyparallel jsonschema six==1.11 \
#    jupyter jupyter_contrib_nbextensions jupyter_nbextensions_configurator
#RUN jupyter contrib nbextension install

RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-ppc64le.sh
RUN bash Anaconda3-2020.02-Linux-ppc64le.sh -b -p /usr/local/anaconda3 -f
ENV PATH /usr/local/anaconda3/bin:$PATH
#RUN eval "$(/usr/local/anaconda3/bin/conda shell.bash hook)"
RUN conda init --system

RUN conda install -c conda-forge boost numpy mpi4py ipyparallel pygraphml
RUN conda install -c conda-forge pandas matplotlib scipy scikit-learn scikit-image
RUN conda install -c conda-forge six jsonschema ipython jupyter nb_conda

RUN mkdir -p /workspace
COPY mpi_bw.c /workspace
RUN mpicc -o /workspace/mpi_bw /workspace/mpi_bw.c

RUN echo "/data/inglib/power8/bin" >> /etc/ld.so.conf.d/ibf.conf && ldconfig

COPY slurm/status_slurm.sh /usr/local/bin/status_slurm.sh
COPY slurm/start_slurm.sh /usr/local/bin/start_slurm.sh
COPY slurm/stop_slurm.sh /usr/local/bin/stop_slurm.sh

COPY slurm/base_slurm.conf /usr/local/etc/base_slurm.conf
COPY slurm/gres.conf /usr/local/etc/gres.conf

RUN chmod a+rx /usr/local/bin/status_slurm.sh
RUN chmod a+rx /usr/local/bin/start_slurm.sh
RUN chmod a+rx /usr/local/bin/stop_slurm.sh

ADD AppDef.json /etc/NAE/AppDef.json
RUN wget --post-file=/etc/NAE/AppDef.json --no-verbose https://api.jarvice.com/jarvice/validate -O -

RUN ln -s /usr/local/bin/start_slurm.sh /etc/init.d/start_slurm
RUN update-rc.d start_slurm defaults

RUN echo "#!/bin/bash\n/data/andmax/all_create_user.sh\n/data/andmax/all_start_jupyter.sh" > /etc/init.d/all_up.sh
RUN chmod a+rx /etc/init.d/all_up.sh
RUN update-rc.d all_up.sh defaults

EXPOSE 22
