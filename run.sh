#!/bin/bash

# Define workspace path on the host system
HOST_WS_PATH="$HOME/turtlebot3_ws"

# 1. Identify Devices Dynamically
OPENCR_PORT=$(find /dev -name "ttyACM*" | head -n 1)
LDS_PORT=/dev/tb3_lidar
CAMERA_PORT=$(v4l2-ctl --list-devices | awk '/rpi-hevc-dec/{getline; print $1}')

# 2. Validation Check
if [ -z "$OPENCR_PORT" ]; then echo "WARNING: OpenCR not found on ttyACM*"; fi
if [ -z "$LDS_PORT" ]; then echo "WARNING: LDS-02 not found on ttyUSB*"; fi
if [ -z "$CAMERA_PORT" ]; then echo "WARNING: Camera not found on video*"; fi

# 3. Build Mount Flags
DEVICE_ARGS=""
[ -n "$OPENCR_PORT" ] && DEVICE_ARGS="$DEVICE_ARGS --device=$OPENCR_PORT"
[ -n "$LDS_PORT" ]    && DEVICE_ARGS="$DEVICE_ARGS --device=$LDS_PORT"
[ -n "$CAMERA_PORT" ] && DEVICE_ARGS="$DEVICE_ARGS --device=$CAMERA_PORT"

# Hardcode GPIO for Raspberry Pi
[ -e "/dev/gpiomem" ] && DEVICE_ARGS="$DEVICE_ARGS --device=/dev/gpiomem"

echo "Passing Devices: $DEVICE_ARGS"
echo "OpenCR ENV: $OPENCR_PORT | LDS ENV: $LDS_PORT | Camera ENV: $CAMERA_PORT"

# 4. Run the Ephemeral Container
echo "Starting runtime container..."
docker run -it --rm \
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
    tb3_humble_base
