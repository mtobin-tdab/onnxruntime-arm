# Import info for 32-bit Qemu based build
# There are also raspberry pi 4 and 64-bit images available so adjust as required
FROM balenalib/raspberrypi3-python:latest-stretch-build
# FROM balenalib/raspberrypi3:buster

ARG ONNXRUNTIME_REPO=https://github.com/Microsoft/onnxruntime
ARG ONNXRUNTIME_SERVER_BRANCH=master

# Enforces cross-compilation through Qemu.
RUN [ "cross-build-start" ]

RUN install_packages \
    sudo \
    build-essential \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    wget \
    python3 \
    python3-dev \
    git \
    tar \
    libatlas-base-dev

# Carefully install the latest version of pip 
WORKDIR /pip
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3 get-pip.py
RUN pip3 install --upgrade setuptools
RUN pip3 install --upgrade wheel
RUN pip3 install numpy

# Build the latest cmake
WORKDIR /code
RUN wget https://github.com/Kitware/CMake/releases/download/v3.18.3/cmake-3.18.3.tar.gz
RUN tar zxf cmake-3.18.3.tar.gz 

WORKDIR /code/cmake-3.18.3
RUN ./configure --system-curl
RUN make
RUN sudo make install

# if doing a 64-bit build change '--arm' to '--arm64'
ARG BUILDARGS="--config MinSizeRel --arm"

# Prepare onnxruntime Repo
WORKDIR /code
RUN git clone --single-branch --branch ${ONNXRUNTIME_SERVER_BRANCH} --recursive ${ONNXRUNTIME_REPO} onnxruntime

# Build ORT including the shared lib and python bindings
WORKDIR /code/onnxruntime
RUN ./build.sh --use_openmp ${BUILDARGS} --update --build --build_shared_lib --build_wheel

RUN [ "cross-build-end" ]
