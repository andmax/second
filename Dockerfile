# IBM PowerPC 64 ppc64
#FROM nvidia/cuda-ppc64le:9.2-cudnn7-devel-ubuntu16.04
#FROM nvidia/cuda-ppc64le:11.0-cudnn8-devel-ubuntu18.04
# Intel/AMD 64-bit x86_64
FROM nvidia/cuda:11.2.1-cudnn8-devel-ubuntu20.04
LABEL maintainer="andmax@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=US/Central
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends curl wget tar file htop nano vim emacs
RUN apt-get -y clean

RUN curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh | bash -s

RUN apt-get update -y --fix-missing
RUN apt-get install -y --no-install-recommends pkg-config debhelper dkms build-essential software-properties-common
RUN apt-get install -y --no-install-recommends pciutils iputils-ping apt-utils hwloc ltrace strace ibverbs-utils
RUN apt-get install -y --no-install-recommends gcc g++ gfortran perl make cmake-curses-gui cmake-gui autotools-dev
RUN apt-get install -y --no-install-recommends libboost-all-dev xutils-dev qtbase5-dev qt5-default numactl libnuma1 libnuma-dev
RUN apt-get install -y --no-install-recommends libxslt-dev libmunge-dev libxml2-dev libopenblas-dev liblapack-dev
RUN apt-get install -y --no-install-recommends libffi-dev libgeos-dev libicu-dev libbz2-dev liblz-dev
RUN apt-get install -y --no-install-recommends texlive-xetex libfreetype6-dev gnuplot graphviz libpng-dev
RUN apt-get install -y --no-install-recommends bzip2 perftest cron
RUN apt-get update -y --fix-missing
RUN apt-get install -y --no-install-recommends libmysqlclient-dev libhdf5-dev hdf5-tools libmunge2 munge
#RUN apt-get install -y --no-install-recommends automake autoconf libtool libevent-dev libhwloc-dev
#RUN apt-get install -y --no-install-recommends python3-pip
#RUN apt-get install -y --no-install-recommends python3-docker
#RUN apt-get install -y --no-install-recommends cuda-samples-9-2
#RUN apt-get install -y --no-install-recommends cuda-samples-11-0
RUN apt-get -y clean

# Compiling cuda samples is not needed since it was installed via apt
#ENV LD_LIBRARY_PATH=/usr/lib/nvidia-410:$LD_LIBRARY_PATH
#RUN cd /usr/local/cuda/samples && make -j"$(nproc)" -k &> /dev/null ; exit 0

RUN mkdir -p /var/tmp

# We don't need to use PMIX to fix SLURM-MPI integration
#ENV PMIX_V=3.1.6
#RUN wget -q -nc --no-check-certificate -P /var/tmp https://github.com/openpmix/openpmix/releases/download/v${PMIX_V}/pmix-${PMIX_V}.tar.bz2
#RUN tar -j -x -f /var/tmp/pmix-${PMIX_V}.tar.bz2 -C /var/tmp
#WORKDIR /var/tmp/pmix-${PMIX_V}
#RUN ./autogen.pl
#RUN ./configure --prefix=/usr/local/pmix
#RUN make all install
#RUN echo "/usr/local/pmix/lib" >> /etc/ld.so.conf.d/pmix.conf
#RUN ldconfig
#RUN rm -rf /var/tmp/pmix-${PMIX_V}.tar.bz2 /var/tmp/pmix-${PMIX_V}

#ENV SLURM_V=20.02.3
ENV SLURM_V=20.11.3
RUN mkdir -p /var/spool/slurm/d /var/spool/slurm/ctld /var/run/slurm /var/log/slurm
RUN wget -q -nc --no-check-certificate -P /var/tmp https://download.schedmd.com/slurm/slurm-${SLURM_V}.tar.bz2
RUN tar -j -x -f /var/tmp/slurm-${SLURM_V}.tar.bz2 -C /var/tmp
WORKDIR /var/tmp/slurm-${SLURM_V}
# IBM PowerPC 64 ppc64
#RUN ./configure --with-mysql_config=/usr/bin --with-hdf5=no --with-munge=/usr/lib/libmunge.so
# Intel/AMD 64-bit x86_64
RUN ./configure --with-mysql_config=/usr/bin --with-hdf5=no --with-munge=/usr/lib/x86_64-linux-gnu/libmunge.so
# To configure SLURM with PMIX should add the below line to the configure command:
#    --with-pmix=/usr/local/pmix --with-hwloc=/usr
RUN make -j"$(nproc)"
RUN make -j"$(nproc)" install
RUN ldconfig
WORKDIR /var/tmp/slurm-${SLURM_V}/contribs/pmi2
RUN make -j"$(nproc)" install
RUN ldconfig
RUN rm -rf /var/tmp/slurm-${SLURM_V}.tar.bz2 /var/tmp/slurm-${SLURM_V}

ENV OMPI_B=3.1
ENV OMPI_V=${OMPI_B}.1
RUN wget -q -nc --no-check-certificate -P /var/tmp https://www.open-mpi.org/software/ompi/v${OMPI_B}/downloads/openmpi-${OMPI_V}.tar.bz2
RUN tar -j -x -f /var/tmp/openmpi-${OMPI_V}.tar.bz2 -C /var/tmp
WORKDIR /var/tmp/openmpi-${OMPI_V}
RUN ./configure --prefix=/usr/local/openmpi --disable-getpwuid \
    --enable-orterun-prefix-by-default --with-cuda=/usr/local/cuda --with-verbs --with-slurm \
    --with-pmi=/usr/local/include/slurm --with-pmi-libdir=/usr/local/lib \
    CPPFLAGS=-I/usr/local/include/slurm LDFLAGS=-L/usr/local/lib
#    --with-pmix=/usr/local/pmix --with-libevent=/usr --with-hwloc=/usr
RUN make -j"$(nproc)"
RUN make -j"$(nproc)" install
RUN echo "/usr/local/openmpi/lib" >> /etc/ld.so.conf.d/openmpi.conf
RUN ldconfig
RUN rm -rf /var/tmp/openmpi-${OMPI_V}.tar.bz2 /var/tmp/openmpi-${OMPI_V}

ENV LD_LIBRARY_PATH=/usr/local/openmpi/lib:$LD_LIBRARY_PATH
# IBM PowerPC 64 ppc64
#ENV LD_LIBRARY_PATH=/usr/lib/powerpc64le-linux-gnu:$LD_LIBRARY_PATH
ENV PATH=/usr/local/openmpi/bin:$PATH

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

# IBM PowerPC 64 ppc64
#ENV ANACONDA_V=Anaconda3-2020.11-Linux-ppc64le
# Intel/AMD 64-bit x86_64
ENV ANACONDA_V=Anaconda3-2020.11-Linux-x86_64
ENV ANACONDA_D=/usr/local/anaconda3
RUN wget https://repo.anaconda.com/archive/${ANACONDA_V}.sh
RUN bash ${ANACONDA_V}.sh -b -p ${ANACONDA_D} -f
ENV PATH ${ANACONDA_D}/bin:$PATH
RUN conda init --system
RUN conda update -y conda
# The below hack is not needed since conda init system does the shell hook
RUN eval "$(/usr/local/anaconda3/bin/conda shell.bash hook)"

RUN conda install -y python=3.7
RUN conda install -y -c conda-forge boost==1.67
RUN conda install -y -c conda-forge six setuptools pygraphml jsonschema numpy
RUN conda install -y -c conda-forge pandas matplotlib scipy scikit-learn scikit-image
RUN conda install -y -c conda-forge ipython ipywidgets jupyter notebook
#RUN conda install mpi4py

# We do need pip inside anaconda to install its package also inside conda env
RUN conda install -y pip

# There is no need for ipcluster and mpi4py
#RUN conda install -c conda-forge ipyparallel
#RUN pip install mpi4py

RUN pip install glances
#RUN curl -L https://bit.ly/glances | /bin/bash

RUN mkdir -p /workspace
COPY mpi_bw.c /workspace
RUN mpicc -o /workspace/mpi_bw /workspace/mpi_bw.c

# IBF will be deployed by SNAIL at /usr/local/lib
#RUN echo "/data/inglib/power8/bin" >> /etc/ld.so.conf.d/ibf.conf && ldconfig

ADD AppDef.json /etc/NAE/AppDef.json
# Old api.jarvice.com platform
#RUN wget --post-file=/etc/NAE/AppDef.json --no-verbose https://api.jarvice.com/jarvice/validate -O -
# New cloud.nimbix.net platform
RUN curl --fail -X POST -d @/etc/NAE/AppDef.json https://cloud.nimbix.net/api/jarvice/validate

COPY rc-local.service /etc/systemd/system/
COPY rc.local /etc/

RUN chmod a+rx /etc/rc.local
RUN systemctl enable rc-local.service

EXPOSE 22
