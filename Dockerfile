# Copyright (c) 2022, NVIDIA CORPORATION.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Generate a Vulkan SDK using a sample build command-line:
#sudo docker build --pull -t \
#   nvidia/vulkan:1.3-470 \
#   --build-arg BASE_DIST=ubuntu20.04 \
#   --build-arg CUDA_VERSION=11.4.2 \
#   --build-arg VULKAN_SDK_VERSION=`curl https://vulkan.lunarg.com/sdk/latest/linux.txt` \
#   --file docker/Dockerfile.ubuntu .
#
ARG DEBIAN_FRONTEND=noninteractive
ARG BASE_DIST=ubuntu24.04
ARG CUDA_VERSION=12.5.1
FROM nvidia/cuda:${CUDA_VERSION}-base-${BASE_DIST}

RUN apt-get update && apt-get install -y --no-install-recommends \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1  \
    libgles2  \
    libxcb1-dev \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

#set VULKAN_SDK_VERSION as a build-arg=`curl https://vulkan.lunarg.com/sdk/latest/linux.txt`
ARG VULKAN_SDK_VERSION=1.3.290.0
# Download the Vulkan SDK and extract the headers, loaders, layers and binary utilities
RUN wget -q --show-progress \
    --progress=bar:force:noscroll \
    https://sdk.lunarg.com/sdk/download/latest/linux/vulkan_sdk.tar.gz \
    -O /tmp/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.gz \ 
    && echo "Installing Vulkan SDK ${VULKAN_SDK_VERSION}" \
    && mkdir -p /opt/vulkan \
    && tar -xf /tmp/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.gz -C /opt/vulkan \
    && mkdir -p /usr/local/include/ && cp -ra /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/include/* /usr/local/include/ \
    && mkdir -p /usr/local/lib && cp -ra /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/lib/* /usr/local/lib/ \
    && cp -a /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/lib/libVkLayer_*.so /usr/local/lib \
    && mkdir -p /usr/local/share/vulkan/explicit_layer.d \
    && cp /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/share/vulkan/explicit_layer.d/VkLayer_*.json /usr/local/share/vulkan/explicit_layer.d \
    && mkdir -p /usr/local/share/vulkan/registry \
    && cp -a /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/share/vulkan/registry/* /usr/local/share/vulkan/registry \
    && cp -a /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/bin/* /usr/local/bin \
    && ldconfig \
    && rm /tmp/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.gz && rm -rf /opt/vulkan

RUN deluser ubuntu && rm -rf /home/ubuntu

# Setup the required capabilities for the container runtime    
ENV NVIDIA_DRIVER_CAPABILITIES=all

