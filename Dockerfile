FROM nvidia/cuda-ppc64le:9.2-cudnn7-runtime-ubuntu16.04
#FROM nvidia/cuda-ppc64le:11.0-cudnn8-runtime-ubuntu18.04
LABEL maintainer="andmax@gmail.com"

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends curl wget tar file htop nano vim emacs
RUN apt-get -y clean

RUN curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh | bash -s

RUN apt-get update -y --fix-missing
RUN apt-get install -y --no-install-recommends pkg-config debhelper dkms build-essential software-properties-common
RUN apt-get install -y --no-install-recommends pciutils iputils-ping apt-utils hwloc ltrace strace ibverbs-utils libnccl2
RUN apt-get install -y --no-install-recommends gcc g++ gfortran perl make cmake-curses-gui cmake-gui autotools-dev
RUN apt-get install -y --no-install-recommends libboost-all-dev xutils-dev qtbase5-dev qt5-default numactl libnuma1 libnuma-dev
RUN apt-get install -y --no-install-recommends libxslt-dev libmunge-dev libxml2-dev libopenblas-dev liblapack-dev
RUN apt-get install -y --no-install-recommends libnccl-dev libffi-dev libgeos-dev libicu-dev libbz2-dev liblz-dev
RUN apt-get install -y --no-install-recommends texlive-xetex libfreetype6-dev gnuplot graphviz libpng-dev
RUN apt-get install -y --no-install-recommends bzip2 perftest cron automake autoconf libtool libevent-dev libhwloc-dev
RUN apt-get update -y --fix-missing
RUN apt-get install -y --no-install-recommends libmysqlclient-dev libhdf5-dev hdf5-tools libmunge2 munge
RUN apt-get install -y --no-install-recommends cuda-samples-9-2
#RUN apt-get install -y --no-install-recommends cuda-samples-11-0
RUN apt-get -y clean

# Compiling cuda samples is not needed since it was installed via apt
#ENV LD_LIBRARY_PATH=/usr/lib/nvidia-410:$LD_LIBRARY_PATH
#RUN cd /usr/local/cuda/samples && make -j"$(nproc)" -k &> /dev/null ; exit 0

RUN mkdir -p /var/tmp

ENV PMIX_V=3.1.6
RUN wget -q -nc --no-check-certificate -P /var/tmp https://github.com/openpmix/openpmix/releases/download/v${PMIX_V}/pmix-${PMIX_V}.tar.bz2
RUN tar -j -x -f /var/tmp/pmix-${PMIX_V}.tar.bz2 -C /var/tmp
WORKDIR /var/tmp/pmix-${PMIX_V}
RUN ./autogen.pl
RUN ./configure --prefix=/usr/local/pmix
RUN make all install
RUN echo "/usr/local/pmix/lib" >> /etc/ld.so.conf.d/pmix.conf
RUN ldconfig
RUN rm -rf /var/tmp/pmix-${PMIX_V}.tar.bz2 /var/tmp/pmix-${PMIX_V}

ENV OMPI_B=3.1
ENV OMPI_V=${OMPI_B}.1
RUN wget -q -nc --no-check-certificate -P /var/tmp https://www.open-mpi.org/software/ompi/v${OMPI_B}/downloads/openmpi-${OMPI_V}.tar.bz2
RUN tar -j -x -f /var/tmp/openmpi-${OMPI_V}.tar.bz2 -C /var/tmp
WORKDIR /var/tmp/openmpi-${OMPI_V}
RUN ./configure --prefix=/usr/local/openmpi --disable-getpwuid \
    --enable-orterun-prefix-by-default --with-cuda=/usr/local/cuda --with-verbs \
    --with-slurm --with-pmix=/usr/local/pmix --with-libevent=/usr --with-hwloc=/usr
RUN make -j"$(nproc)"
RUN make -j"$(nproc)" install
RUN echo "/usr/local/openmpi/lib" >> /etc/ld.so.conf.d/openmpi.conf
RUN ldconfig
RUN rm -rf /var/tmp/openmpi-${OMPI_V}.tar.bz2 /var/tmp/openmpi-${OMPI_V}

ENV LD_LIBRARY_PATH=/usr/local/openmpi/lib:/usr/lib/powerpc64le-linux-gnu:$LD_LIBRARY_PATH \
    PATH=/usr/local/openmpi/bin:$PATH

#ENV SLURM_V=20.02.3
ENV SLURM_V=20.11.3
RUN mkdir -p /var/spool/slurm/d /var/spool/slurm/ctld /var/run/slurm /var/log/slurm
RUN wget -q -nc --no-check-certificate -P /var/tmp https://download.schedmd.com/slurm/slurm-${SLURM_V}.tar.bz2
RUN tar -j -x -f /var/tmp/slurm-${SLURM_V}.tar.bz2 -C /var/tmp
WORKDIR /var/tmp/slurm-${SLURM_V}
RUN ./configure --with-mysql_config=/usr/bin --with-hdf5=no --with-munge=/usr/lib/libmunge.so \
    --with-pmix=/usr/local/pmix --with-hwloc=/usr
RUN make -j"$(nproc)"
RUN make -j"$(nproc)" install
RUN rm -rf /var/tmp/slurm-${SLURM_V}.tar.bz2 /var/tmp/slurm-${SLURM_V}

# Removing ubuntu openmpi breaks other packages, better not
#RUN apt-get -y remove openmpi-bin
RUN apt-get -y autoremove
RUN apt-get -y autoclean
RUN apt-get -y update

# Better replace pip by anaconda
#RUN pip3 install --upgrade pip setuptools
#RUN pip3 install matplotlib pygraphml scipy pandas numpy \
#    mpi4py sockets ipython ipyparallel jsonschema six==1.11 \
#    jupyter jupyter_contrib_nbextensions jupyter_nbextensions_configurator
#RUN jupyter contrib nbextension install

RUN pip install --upgrade pip

RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-ppc64le.sh
RUN bash Anaconda3-2020.02-Linux-ppc64le.sh -b -p /usr/local/anaconda3 -f
ENV PATH /usr/local/anaconda3/bin:$PATH
RUN conda init --system
RUN conda update conda
# The below hack is not needed since conda init system does the shell hook
#RUN eval "$(/usr/local/anaconda3/bin/conda shell.bash hook)"

RUN conda install -c conda-forge boost numpy setuptools mpi4py pygraphml
RUN conda install -c conda-forge pandas matplotlib scipy scikit-learn scikit-image
RUN conda install -c conda-forge six jsonschema ipython ipywidgets jupyter notebook
# There is no need for ipcluster and mpi4py
#RUN conda install -c conda-forge ipyparallel
#RUN pip install mpi4py

RUN curl -L https://bit.ly/glances | /bin/bash

RUN mkdir -p /workspace
COPY mpi_bw.c /workspace
RUN mpicc -o /workspace/mpi_bw /workspace/mpi_bw.c

RUN echo "/data/inglib/power8/bin" >> /etc/ld.so.conf.d/ibf.conf && ldconfig

ADD AppDef.json /etc/NAE/AppDef.json
RUN wget --post-file=/etc/NAE/AppDef.json --no-verbose https://api.jarvice.com/jarvice/validate -O -

RUN echo "\
#!/bin/bash\n\
/data/snail/slurm_nimbix/install_extra.sh\n\
/data/snail/slurm_nimbix/all_create_user.sh\n\
/data/snail/slurm_nimbix/all_start_jupyter.sh\n\
/data/snail/slurm_nimbix/start_services.sh\
" > /usr/local/bin/all_up.sh
RUN chmod a+rx /usr/local/bin/all_up.sh
RUN sed -i -e '$i /usr/local/bin/all_up.sh\n' /etc/rc.local

EXPOSE 22
