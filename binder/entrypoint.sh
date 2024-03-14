#!/bin/bash
# Launch ros web applications
source ${ROS_WS}/devel/setup.bash
roscore &
roslaunch --wait rvizweb rvizweb.launch &

# Start MongoDB
mongod --fork --logpath ${PWD}/mongod.log

# Launch Knowrob
source ${KNOWROB_WS}/devel/setup.bash

export KNOWROB_MONGODB_URI="mongodb://127.0.0.1:27017/?appname=knowrob"
roslaunch --wait knowrob knowrob.launch &

exec "$@"