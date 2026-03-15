#!/bin/bash

CONTAINER_NAME="turtlebase"
HOST_WS_PATH="$HOME/turtlebot3_ws"

# X11 / GUI Setup
XAUTH=/tmp/.docker.xauth
if [ ! -f $XAUTH ]; then
    touch $XAUTH
    xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
fi

# cleaning
if ls $HOST_WS_PATH/core.* 1> /dev/null 2>&1; then
    echo "Cleaning up old core dump files..."
    rm $HOST_WS_PATH/core.*
fi

# 1. Identify Devices
OPENCR_PORT=$(find /dev -name "ttyACM*" | head -n 1)
LDS_PORT=/dev/tb3_lidar
# Note: For RPi Cam v2, we usually need the video nodes
VIDEO_DEVICES=$(ls /dev/video* 2>/dev/null)

DEVICE_ARGS=""
for dev in $VIDEO_DEVICES; do DEVICE_ARGS="$DEVICE_ARGS --device=$dev"; done
[ -n "$OPENCR_PORT" ] && DEVICE_ARGS="$DEVICE_ARGS --device=$OPENCR_PORT"
[ -n "$LDS_PORT" ]    && DEVICE_ARGS="$DEVICE_ARGS --device=$LDS_PORT"
[ -e "/dev/gpiomem" ] && DEVICE_ARGS="$DEVICE_ARGS --device=/dev/gpiomem"
[ -e "/dev/vchiq" ]   && DEVICE_ARGS="$DEVICE_ARGS --device=/dev/vchiq" # Required for RPi Cam

# 2. Lifecycle
if [ ! "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Creating container with GUI support..."
    docker run -d \
        --name "$CONTAINER_NAME" \
        --net=host \
        --ipc=host \
        --privileged \
        $DEVICE_ARGS \
        -e DISPLAY=$DISPLAY \
        -e XAUTHORITY=$XAUTH \
        -v $XAUTH:$XAUTH \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v "$HOST_WS_PATH:/turtlebot3_ws" \
        -v /dev:/dev \
        tb3_humble_base \
        tail -f /dev/null
elif [ "$(docker ps -f name=^/${CONTAINER_NAME}$ -f status=exited -q)" ]; then
    docker start "$CONTAINER_NAME"
fi

# Allow local connections to X11
xhost +local:docker > /dev/null

docker exec -it "$CONTAINER_NAME" /bin/bash
