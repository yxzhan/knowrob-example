FROM intel4coro/base-notebook:20.04-noetic

# Install SWI Prolog
USER root
RUN apt install -y software-properties-common && \
  apt-add-repository -y ppa:swi-prolog/stable
RUN apt update && \
  apt install -y swi-prolog
ENV SWI_HOME_DIR=/usr/lib/swi-prolog

# Install MongoDB Community Edition
ARG MONGODEB_VERSION=4.4
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODEB_VERSION}.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-${MONGODEB_VERSION}.gpg --dearmor
RUN echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODEB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/${MONGODEB_VERSION} multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-${MONGODEB_VERSION}.list
RUN apt update && apt install -y mongodb-org
RUN mkdir -p /data/db && \
    chown -R ${NB_USER}:users /data/db 

# Init Knowrob catkin workspace
USER ${NB_USER}
ENV KNOWROB_WS=${HOME}/workspace/knowrob
RUN mkdir -p ${KNOWROB_WS}/src
WORKDIR ${KNOWROB_WS}/src
RUN wstool init && \
    wstool merge https://raw.github.com/knowrob/knowrob/master/rosinstall/knowrob-base.rosinstall && \
    wstool update

# Switch to root user to install ROS dependencies
USER root
RUN rosdep update && rosdep install -y -r --ignore-src --from-paths . && \
    rosdep fix-permissions

# Install jupyter knowrob kernel
USER ${NB_USER}
WORKDIR ${HOME}
RUN git clone https://github.com/sasjonge/jupyter-knowrob.git --recurse-submodules
RUN cd jupyter-knowrob && pip install .
ARG JK_KERNEL=${HOME}/.local/share/jupyter/kernels/jknowrob
RUN mkdir -p ${JK_KERNEL} && \
    cp jupyter-knowrob/kernel.json ${JK_KERNEL}
RUN cp -R ${HOME}/jupyter-knowrob/knowrob_cloud ${KNOWROB_WS}/src/
USER root
RUN cp -R ${HOME}/jupyter-knowrob/prolog /

# Build catkin workspace
USER ${NB_USER}
WORKDIR ${KNOWROB_WS}
RUN source ${ROS_PATH}/setup.bash && catkin_make

# Source knowrob workspace when a new bash shell opens
RUN echo "source ${KNOWROB_WS}/devel/setup.bash" >> ${HOME}/.bashrc

USER ${NB_USER}
# jupyterlab interface configuration
COPY --chown=${NB_USER}:users binder/jupyter-settings.json /opt/conda/share/jupyter/lab/settings/overrides.json
COPY --chown=${NB_USER}:users binder/webapps.json ${ROS_WS}/src/rvizweb/webapps/app.json

# Entrypoint starting knowrob and mongodb
COPY --chown=${NB_USER}:users binder/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

WORKDIR ${HOME}/jupyter-knowrob/lectures
RUN ln -s ${KNOWROB_WS} ${PWD}/KNOWROB_WS
