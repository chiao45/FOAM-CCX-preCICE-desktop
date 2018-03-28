# Build preCICE with OpenFOAM and CalculiX
# Authors: Qiao Chen

FROM compdatasci/spyder-desktop:latest
LABEL maintainer "Qiao Chen <benechiao@gmail.com>"

USER root
WORKDIR /tmp

ENV PRECICE_VERSION=1.0.3
ENV PRECICE_ROOT=$DOCKER_HOME/precice-$PRECICE_VERSION

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
    cd $PRECICE_ROOT && \
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

# post processing
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo 'source /opt/openfoam5/etc/bashrc' >> $DOCKER_HOME/.profile && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
USER root
