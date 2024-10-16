FROM python:3.9

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        curl \
        gcc \
        g++ && \
    rm -rf /var/lib/apt/lists/*

# Switch to Ubuntu 22.04 repositories
RUN sed -i 's/focal/jammy/g' /etc/apt/sources.list

# Update package lists and upgrade installed packages
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Install NVIDIA CUDA 11.8
# Add NVIDIA package repositories
RUN curl -fsSL https://developer.download.nvidia.com/cuda/ubuntu2204/cuda-keyring_1.0-1_all.deb \
    | debian-fronten=noninteractive dpkg -i -
RUN echo "deb  https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64  /" > /etc/apt/sources.list.d/cuda.list
RUN apt-get update

# Install CUDA 11.8
RUN apt-get install -y --no-install-recommends \
    cuda-11-8 \
    libcudnn8=8.6.0.163-1+cuda11.8 \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for CUDA
ENV PATH /usr/local/cuda-11.8/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/cuda-11.8/lib64:${LD_LIBRARY_PATH}

# Install Python tools for Ubuntu 22.04
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.9-venv && \
    rm -rf /var/lib/apt/lists/*
