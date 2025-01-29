FROM tiryoh/ros-desktop-vnc:noetic

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

# Install various useful tools
RUN apt update && apt install -y \
    openjdk-11-jdk \
    lsb-release \
    gnupg \
    ant \
    && rm -rf /var/lib/apt/list

# Installing ros-bridge-server
RUN apt update && apt install -y \
    ros-noetic-rosbridge-server \
    && rm -rf /var/lib/apt/list

## Install maven
RUN wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
RUN tar -xvf apache-maven-3.9.9-bin.tar.gz
RUN mv apache-maven-3.9.9 /opt/
ENV M2_HOME='/opt/apache-maven-3.9.9'
ENV PATH="$M2_HOME/bin:$PATH"

## Some of this stuff wants a user so we will create one
RUN groupadd -g 1000 mcapl-ros \
    && adduser --disabled-password --gid 1000  --gecos '' mcapl-ros \
    && adduser mcapl-ros sudo

ENV USER=mcapl-ros
ENV HOME=/home/mcapl-ros

## Seem to need to set the locale to get mvn and ant to recoginse some characters
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.en
ENV LC_ALL=en_US.UTF-8

## Install javarosbridge
ENV JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-$TARGETARCH

WORKDIR $HOME

RUN git clone https://github.com/h2r/java_rosbridge.git

WORKDIR $HOME/java_rosbridge
RUN  mvn package

## Install MCAPL
WORKDIR $HOME
RUN git clone https://github.com/mcapl/mcapl.git
RUN mkdir -p $HOME/.jpf && touch $HOME/.jpf/site.properties
RUN echo "mcapl = $HOME/mcapl" >> $HOME/.jpf/site.properties

ENV AJPF_HOME=$HOME/mcapl
ENV CLASSPATH=$HOME/mcapl/bin
WORKDIR $HOME/mcapl
RUN ant compile

# Install useful ROS packages
RUN apt update && apt install -y \
    ros-noetic-navigation \
    ros-noetic-jackal-* \
    && rm -rf /var/lib/apt/list

# Install gazebo
RUN sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
RUN sudo curl https://packages.osrfoundation.org/gazebo.key | sudo apt-key add -
RUN apt update && apt install -y \
    ros-noetic-gazebo-ros \
    && rm -rf /var/lib/apt/list

# Install radiation store
RUN mkdir -p $HOME/catkin_ws/src

WORKDIR $HOME/catkin_ws/src
RUN git clone https://github.com/EEEManchester/gazebo_radiation_plugin.git
RUN git clone https://github.com/EEEManchester/simple_radiation_layer.git
RUN cp simple_radiation_layer/radmap_params.yaml gazebo_radiation_plugin/launch/params/.
WORKDIR $HOME/catkin_ws
RUN ["/bin/bash", "-c", "source /opt/ros/noetic/setup.bash \
    catkin_make"]

COPY ./entrypoint.sh /
ENTRYPOINT [ "/bin/bash", "-c", "/entrypoint.sh" ]