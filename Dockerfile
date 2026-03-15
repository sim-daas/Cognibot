FROM ros:humble-ros-base

# Disable prompts during apt installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    ros-humble-cyclonedds \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-turtlebot3 \
    ros-humble-turtlebot3-msgs \
    ros-humble-dynamixel-sdk \
    ros-humble-ld08-driver \
    ros-humble-v4l2-camera \
    ros-humble-hls-lfcd-lds-driver \
    ros-humble-xacro \
    libudev-dev \
    python3-colcon-common-extensions \
    build-essential \
    git \
    nano \
    udev \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables natively
ENV ROS_DOMAIN_ID=184
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ENV TURTLEBOT3_MODEL=burger
ENV LDS_MODEL=LDS-02
RUN mkdir -p /turtlebot3_ws

# Source ROS 2 entrypoint globally
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc
RUN echo "source /turtlebot3_ws/install/setup.bash" >> /root/.bashrc

WORKDIR /turtlebot3_ws
CMD ["/bin/bash"]
