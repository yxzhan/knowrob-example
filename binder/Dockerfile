# Dockerfile of the base image: https://github.com/IntEL4CoRo/docker-stacks/blob/remote-desktop/Dockerfile
FROM intel4coro/base-notebook:20.04-noetic-vnc

# Path to the default ROS workspace
ENV ROS_WS=${HOME}/workspace/ros

#============= Install extra software packages =============#

# Install Redland, Raptor2, libmongoc, spdlog, fmt, gtest
# Source: https://github.com/knowrob/knowrob/blob/dev/docker/noetic_base.Dockerfile
USER root
RUN apt update && \
    apt install -y \
        gdb g++ clang cmake make doxygen \
        libeigen3-dev \
        libspdlog-dev \
        libraptor2-dev \
        librdf0 \
        librdf0-dev \
        libmongoc-1.0-0 \
        libmongoc-dev \
        libgtest-dev \
        libfmt-dev \
        software-properties-common

# Install SWI Prolog
# Source: https://www.swi-prolog.org/build/PPA.html
USER root
RUN apt-add-repository -y ppa:swi-prolog/stable
RUN apt update && \
    apt install -y swi-prolog*
ENV SWI_HOME_DIR=/usr/lib/swi-prolog
ENV LD_LIBRARY_PATH=/usr/lib/swi-prolog/lib/x86_64-linux:$LD_LIBRARY_PATH

# Install MongoDB Community Edition
# Source: https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/#std-label-install-mdb-community-ubuntu
ARG MONGODEB_VERSION=4.4
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODEB_VERSION}.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-${MONGODEB_VERSION}.gpg --dearmor
RUN echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODEB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/${MONGODEB_VERSION} multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-${MONGODEB_VERSION}.list
RUN apt update && apt install -y mongodb-org
RUN mkdir -p /data/db && \
    chown -R ${NB_USER}:users /data/db

# Install MongoDB-Compass
# Source: https://docs.mongodb.com/compass/master/install/
USER root
RUN wget -O /tmp/mongodb-compass.deb https://downloads.mongodb.com/compass/mongodb-compass_1.43.0_amd64.deb && \
    dpkg -i /tmp/mongodb-compass.deb && \
    rm  /tmp/mongodb-compass.deb

# # Install jupyter knowrob kernel
# # Source: https://github.com/sasjonge/jupyter-knowrob
# USER ${NB_USER}
# WORKDIR ${HOME}
# RUN git clone https://github.com/sasjonge/jupyter-knowrob.git --recurse-submodules
# RUN cd jupyter-knowrob && pip install .
# ARG JK_KERNEL=${HOME}/.local/share/jupyter/kernels/jknowrob
# RUN mkdir -p ${JK_KERNEL} && \
#     cp jupyter-knowrob/kernel.json ${JK_KERNEL}
# RUN cp -R ${HOME}/jupyter-knowrob/knowrob_cloud ${ROS_WS}/src/
# COPY --chown=${NB_USER}:users prolog /prolog

# Install Knowrob
# Source: https://github.com/knowrob/knowrob
USER ${NB_USER}
# WORKDIR ${HOME}
WORKDIR ${ROS_WS}/src
# Since the .rosinstall file
# https://github.com/knowrob/knowrob/blob/dev/rosinstall/knowrob-base.rosinstall
# still fetching knowrob from master branch, 
# Here clone the ROS dependencies repository manually
# RUN git clone https://github.com/knowrob/rosprolog.git -b master
# RUN git clone https://github.com/code-iai/iai_common_msgs.git -b master
RUN git clone https://github.com/knowrob/knowrob.git -b dev
WORKDIR ${ROS_WS}/src/knowrob
RUN source ${ROS_WS}/devel/setup.bash && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make
RUN pip install pyros-genmsg
USER root
RUN cd build && make install
USER ${NB_USER}
RUN echo "source ${HOME}/knowrob/build/devel/setup.bash" >> ${HOME}/.bashrc

# Switch to root user to install ROS dependencies
# Source: http://wiki.ros.org/rosdep
WORKDIR ${ROS_WS}
USER root
RUN rosdep update && \
    rosdep install -y -r --ignore-src --from-paths . && \
    rosdep fix-permissions

# Build catkin workspace
# Source: https://catkin-tools.readthedocs.io/en/latest/verbs/catkin_build.html
USER ${NB_USER}
WORKDIR ${ROS_WS}
RUN catkin build

# Download the example neem data
# USER root
# RUN mkdir /neem_data && chown ${NB_USER}:users /neem_data
# USER ${NB_USER}
# RUN cd /neem_data && \
#     wget https://seafile.zfn.uni-bremen.de/f/b66a71b257084d459b6c/?dl=1 -O example_neem.zip && \
#     unzip example_neem.zip && \
#     mv example_neem/* ./ && \
#     rm -r example_neem example_neem.zip
#===========================================================#

# Copy content to the image
USER ${NB_USER}
ENV REPO_DIR=${HOME}/work
WORKDIR ${REPO_DIR}
COPY --chown=${NB_USER}:users . ${REPO_DIR}/

# Create a symbolic link to the ROS workspace under the working directory
RUN ln -s ${ROS_WS} ${PWD}/ROS_WS
# RUN ln -s /neem_data ${PWD}/neem_data
RUN ln -s ${ROS_WS}/src/knowrob ${HOME}/knowrob

# The entrypoint of the docker image
COPY --chown=${NB_USER}:users binder/entrypoint.sh /entrypoint.sh
COPY --chown=${NB_USER}:users binder/webapps.json ${ROS_WS}/src/rvizweb/webapps/app.json
ENTRYPOINT ["/entrypoint.sh"]