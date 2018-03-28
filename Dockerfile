# Build preCICE with OpenFOAM and CalculiX
# Authors: Qiao Chen

FROM compdatasci/spyder-desktop:latest
LABEL maintainer "Qiao Chen <benechiao@gmail.com>"

USER root
WORKDIR /tmp

ENV PRECICE_VERSION=1.0.3
ENV PRECICE_ROOT=$DOCKER_HOME/precice-$PRECICE_VERSION \
    PRECICE_ADAPTERS_ROOT=$DOCKER_HOME/precice-adapters \
    PRECICE_OPENFOAM_ADAPTER_ROOT=$PRECICE_ADAPTERS_ROOT/openfoam-adapter \
    PRECICE_CALCULIX_ADAPTER_ROOT=$PRECICE_ADAPTERS_ROOT/calculix-adapter \
    CALCULIX_REPO_ROOT=$DOCKER_HOME/CalculiX

# step 1 install OpenFOAM and system packages
RUN add-apt-repository http://dl.openfoam.org/ubuntu && \
    sh -c "curl -s http://dl.openfoam.org/gpg.key | apt-key add -" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      openfoam5 \
      scons \
      libxml2-dev \
      libeigen3-dev \
      libboost-log-dev \
      libboost-thread-dev \
      libboost-system-dev \
      libboost-filesystem-dev \
      libboost-program-options-dev \
      libboost-test-dev \
      libyaml-cpp-dev && \
    apt-get clean && \
    mkdir -p $PRECICE_ADAPTERS_ROOT

# step 2 install preCICE
# substep 1 fit Eigen into precice system
RUN ln -s -f /usr/include/eigen3/Eigen /usr/include/Eigen

# substep 2 now begin to install
RUN wget --quiet \
      https://github.com/precice/precice/archive/v$PRECICE_VERSION.tar.gz && \
    tar xf v$PRECICE_VERSION.tar.gz && \
    cp -r precice-$PRECICE_VERSION $DOCKER_HOME && \
    cd &PRECICE_ROOT && \
    scons \
      compiler=mpicxx \
      build=release \
      petsc=yes \
      python=no \
      mpi=yes \
      -j 2 \
      solib \
      symlink

# setup the shared lib path
ENV LD_LIBRARY_PATH=$PRECICE_ROOT/build/last:$LD_LIBRARY_PATH

# step 3 install openfoam adapter
RUN source /opt/openfoam5/etc/bashrc && \
    cd $PRECICE_ADAPTERS_ROOT && \
    git clone --depth 1 https://github.com/precice/openfoam-adapter.git && \
    cd $PRECICE_OPENFOAM_ADAPTER_ROOT && \
    ./Allwmake \
      ADAPTER_PREP_FLAGS="" \
      ADAPTER_WMAKE_OPTIONS="-j 2"

# step 4 install calculix adapter
# substep 1, make yaml-cpp fit into the adapter's makefile
RUN ln -s -f /usr/lib/x86_64-linux-gnu /usr/include/yaml-cpp/build

# substep 2, invoke the makefile
RUN git clone --depth 1 https://github.com/unifem/CalculiX_MT.git && \
    cp -r CalculiX_MT $CALCULIX_REPO_ROOT && \
    cd $PRECICE_ADAPTERS_ROOT && \
    git clone --depth 1 https://github.com/precice/calculix-adapter.git && \
    cd $PRECICE_CALCULIX_ADAPTER_ROOT && \
    make \
      -j2 \
      CCX=$CALCULIX_REPO_ROOT/CalculiX/ccx_2.13/src \
      SPOOLES=$CALCULIX_REPO_ROOT/SPOOLES.2.2 \
      ARPACK=$CALCULIX_REPO_ROOT/ARPACK \
      PRECICE_ROOT=$PRECICE_ROOT \
      YAML=/usr/include/yaml-cpp

# post processing
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo 'export OMP_NUM_THREADS=$(nproc)' >> $DOCKER_HOME/.profile && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
USER root
