# Build preCICE with OpenFOAM and CalculiX
# Authors: Qiao Chen

FROM chiao/foam-ccx-precice-desktop:base
LABEL maintainer "Qiao Chen <benechiao@gmail.com>"

USER root
WORKDIR /tmp

ENV PRECICE_ADAPTERS_ROOT=$DOCKER_HOME/precice-adapters
ENV PRECICE_OPENFOAM_ADAPTER_ROOT=$PRECICE_ADAPTERS_ROOT/openfoam-adapter
ENV PRECICE_CALCULIX_ADAPTER_ROOT=$PRECICE_ADAPTERS_ROOT/calculix-adapter
ENV CALCULIX_REPO_ROOT=$DOCKER_HOME/CalculiX

RUN mkdir -p $PRECICE_ADAPTERS_ROOT

# step 3 install openfoam adapter
RUN cd $PRECICE_ADAPTERS_ROOT && \
    git clone --depth 1 https://github.com/precice/openfoam-adapter.git && \
    cd $PRECICE_OPENFOAM_ADAPTER_ROOT && \
    ./Allwmake \
      ADAPTER_PREP_FLAGS="" \
      ADAPTER_WMAKE_OPTIONS="-j 2"

# step 4 install calculix adapter
# substep 1, make yaml-cpp fit into the adapter's makefile
RUN ln -s -f /usr/lib/x86_64-linux-gnu /usr/local/yaml-cpp/build && \
    ln -s -f /usr/include/yaml-cpp /usr/local/yaml-cpp/include

# substep 2, invoke the makefile
RUN git clone --depth 1 https://github.com/unifem/CalculiX_MT.git && \
    cp -r CalculiX_MT $CALCULIX_REPO_ROOT && \
    cd $PRECICE_ADAPTERS_ROOT && \
    git clone --depth 1 https://github.com/precice/calculix-adapter.git && \
    cd $PRECICE_CALCULIX_ADAPTER_ROOT && \
    make \
      -j2 \
      CALCULIX_HOME=$CALCULIX_REPO_ROOT \
      CCX=$CALCULIX_REPO_ROOT/CalculiX/ccx_2.13/src \
      SPOOLES=$CALCULIX_REPO_ROOT/SPOOLES.2.2 \
      ARPACK=$CALCULIX_REPO_ROOT/ARPACK \
      PRECICE_ROOT=$PRECICE_ROOT \
      YAML=/usr/local/yaml-cpp

# post processing
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo 'export OMP_NUM_THREADS=$(nproc)' >> $DOCKER_HOME/.profile && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
USER root
