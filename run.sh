#!/bin/bash

CONTAINER_NAME="turtlebase"
HOST_WS_PATH="$HOME/turtlebot3_ws"

# cleaning
if ls $HOST_WS_PATH/core.* 1> /dev/null 2>&1; then
    echo "Cleaning up old core dump files..."
    rm $HOST_WS_PATH/core.*
fi


# 1. Identify Devices Dynamically
OPENCR_PORT=$(find /dev -name "ttyACM*" | head -n 1)
LDS_PORT=/dev/tb3_lidar
CAMERA_PORT=$(v4l2-ctl --list-devices | awk '/rpi-hevc-dec/{getline; print $1}')

# 2. Build Mount Flags
DEVICE_ARGS=""
[ -n "$OPENCR_PORT" ] && DEVICE_ARGS="$DEVICE_ARGS --device=$OPENCR_PORT"
[ -n "$LDS_PORT" ]    && DEVICE_ARGS="$DEVICE_ARGS --device=$LDS_PORT"
[ -n "$CAMERA_PORT" ] && DEVICE_ARGS="$DEVICE_ARGS --device=$CAMERA_PORT"
[ -e "/dev/gpiomem" ] && DEVICE_ARGS="$DEVICE_ARGS --device=/dev/gpiomem"

# 3. Handle Container Lifecycle
if [ ! "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Creating and starting new container: $CONTAINER_NAME"
    # Removed --rm and added --name and -d (detached)
    docker run -d \
        --name "$CONTAINER_NAME" \
        --net=host \
        --ipc=host \
        --pid=host \
        --privileged \
        $DEVICE_ARGS \
        -e OPENCR_PORT="$OPENCR_PORT" \
        -e LDS_PORT="$LDS_PORT" \
        -e CAMERA_PORT="$CAMERA_PORT" \
        -v "$HOST_WS_PATH:/turtlebot3_ws" \
        -v /dev:/dev \
        tb3_humble_base \
        tail -f /dev/null # Keeps the container alive in the background
elif [ "$(docker ps -f name=^/${CONTAINER_NAME}$ -f status=exited -q)" ]; then
    echo "Starting existing stopped container..."
    docker start "$CONTAINER_NAME"
fi

# 4. Enter the container
echo "Entering $CONTAINER_NAME..."
docker exec -it "$CONTAINER_NAME" /bin/bash
