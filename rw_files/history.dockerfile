ARG RELEASE
ARG LAUNCHPAD_BUILD_ARCH
LABEL org.opencontainers.image.ref.name=ubuntu
LABEL org.opencontainers.image.version=20.04
ADD file:4809da414c2d478b4d991cbdaa2df457f2b3d07d0ff6cf673f09a66f90833e81 in /
CMD ["/bin/bash"]
ENV NVARCH=x86_64 0B buildkit.dockerfile.v0
ENV NVIDIA_REQUIRE_CUDA=cuda>=11.8 brand=tesla,driver>=470,driver<471 brand=unknown,driver>=470,driver<471 brand=nvidia,driver>=470,driver<471 brand=nvidiartx,driver>=470,driver<471 brand=geforce,driver>=470,driver<471 brand=geforcertx,driver>=470,driver<471 brand=quadro,driver>=470,driver<471 brand=quadrortx,driver>=470,driver<471 brand=titan,driver>=470,driver<471 brand=titanrtx,driver>=470,driver<471 0B buildkit.dockerfile.v0
ENV NV_CUDA_CUDART_VERSION=11.8.89-1 0B buildkit.dockerfile.v0
ENV NV_CUDA_COMPAT_PACKAGE=cuda-compat-11-8 0B buildkit.dockerfile.v0
ARG TARGETARCH 0B buildkit.dockerfile.v0
LABEL maintainer=NVIDIA CORPORATION <cudatools@nvidia.com> 0B buildkit.dockerfile.v0
RUN |1 TARGETARCH=amd64 /bin/sh -c apt-get update \
   &&  apt-get install -y --no-install-recommends gnupg2 curl ca-certificates \
   &&  curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/${NVARCH}/3bf863cc.pub | apt-key add - \
   &&  echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/${NVARCH} /" > /etc/apt/sources.list.d/cuda.list \
   &&  apt-get purge --autoremove -y curl \
   &&  rm -rf /var/lib/apt/lists/* # buildkit 18.3MB buildkit.dockerfile.v0
ENV CUDA_VERSION=11.8.0 0B buildkit.dockerfile.v0
RUN |1 TARGETARCH=amd64 /bin/sh -c apt-get update \
   &&  apt-get install -y --no-install-recommends cuda-cudart-11-8=${NV_CUDA_CUDART_VERSION} ${NV_CUDA_COMPAT_PACKAGE} \
   &&  rm -rf /var/lib/apt/lists/* # buildkit 151MB buildkit.dockerfile.v0
RUN |1 TARGETARCH=amd64 /bin/sh -c echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf \
   &&  echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf # buildkit 46B buildkit.dockerfile.v0
ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin 0B buildkit.dockerfile.v0
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64 0B buildkit.dockerfile.v0
COPY NGC-DL-CONTAINER-LICENSE / # buildkit 17.3kB buildkit.dockerfile.v0
ENV NVIDIA_VISIBLE_DEVICES=all 0B buildkit.dockerfile.v0
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility 0B buildkit.dockerfile.v0
ENV NV_CUDA_LIB_VERSION=11.8.0-1 0B buildkit.dockerfile.v0
ENV NV_NVTX_VERSION=11.8.86-1 0B buildkit.dockerfile.v0
ENV NV_LIBNPP_VERSION=11.8.0.86-1 0B buildkit.dockerfile.v0
ENV NV_LIBNPP_PACKAGE=libnpp-11-8=11.8.0.86-1 0B buildkit.dockerfile.v0
ENV NV_LIBCUSPARSE_VERSION=11.7.5.86-1 0B buildkit.dockerfile.v0
ENV NV_LIBCUBLAS_PACKAGE_NAME=libcublas-11-8 0B buildkit.dockerfile.v0
ENV NV_LIBCUBLAS_VERSION=11.11.3.6-1 0B buildkit.dockerfile.v0
ENV NV_LIBCUBLAS_PACKAGE=libcublas-11-8=11.11.3.6-1 0B buildkit.dockerfile.v0
ENV NV_LIBNCCL_PACKAGE_NAME=libnccl2 0B buildkit.dockerfile.v0
ENV NV_LIBNCCL_PACKAGE_VERSION=2.16.2-1 0B buildkit.dockerfile.v0
ENV NCCL_VERSION=2.16.2-1 0B buildkit.dockerfile.v0
ENV NV_LIBNCCL_PACKAGE=libnccl2=2.16.2-1+cuda11.8 0B buildkit.dockerfile.v0
ARG TARGETARCH 0B buildkit.dockerfile.v0
LABEL maintainer=NVIDIA CORPORATION <cudatools@nvidia.com> 0B buildkit.dockerfile.v0
RUN |1 TARGETARCH=amd64 /bin/sh -c apt-get update \
   &&  apt-get install -y --no-install-recommends cuda-libraries-11-8=${NV_CUDA_LIB_VERSION} ${NV_LIBNPP_PACKAGE} cuda-nvtx-11-8=${NV_NVTX_VERSION} libcusparse-11-8=${NV_LIBCUSPARSE_VERSION} ${NV_LIBCUBLAS_PACKAGE} ${NV_LIBNCCL_PACKAGE} \
   &&  rm -rf /var/lib/apt/lists/* # buildkit 2.42GB buildkit.dockerfile.v0
RUN |1 TARGETARCH=amd64 /bin/sh -c apt-mark hold ${NV_LIBCUBLAS_PACKAGE_NAME} ${NV_LIBNCCL_PACKAGE_NAME} # buildkit 258kB buildkit.dockerfile.v0
COPY entrypoint.d/ /opt/nvidia/entrypoint.d/ # buildkit 3.06kB buildkit.dockerfile.v0
COPY nvidia_entrypoint.sh /opt/nvidia/ # buildkit 2.53kB buildkit.dockerfile.v0
ENV NVIDIA_PRODUCT_NAME=CUDA 0B buildkit.dockerfile.v0
ENTRYPOINT ["/opt/nvidia/nvidia_entrypoint.sh"] 0B buildkit.dockerfile.v0
ENV NV_CUDNN_VERSION=8.9.6.50 0B buildkit.dockerfile.v0
ENV NV_CUDNN_PACKAGE_NAME=libcudnn8 0B buildkit.dockerfile.v0
ENV NV_CUDNN_PACKAGE=libcudnn8=8.9.6.50-1+cuda11.8 0B buildkit.dockerfile.v0
ARG TARGETARCH 0B buildkit.dockerfile.v0
LABEL maintainer=NVIDIA CORPORATION <cudatools@nvidia.com> 0B buildkit.dockerfile.v0
LABEL com.nvidia.cudnn.version=8.9.6.50 0B buildkit.dockerfile.v0
RUN |1 TARGETARCH=amd64 /bin/sh -c apt-get update \
   &&  apt-get install -y --no-install-recommends ${NV_CUDNN_PACKAGE} \
   &&  apt-mark hold ${NV_CUDNN_PACKAGE_NAME} \
   &&  rm -rf /var/lib/apt/lists/* # buildkit 1.09GB buildkit.dockerfile.v0
RUN apt-get update \
   &&  apt-get install -y --no-install-recommends python3 python3-pip python3.8-venv \
   &&  rm -rf /var/lib/apt/lists/*
RUN apt-get update \
   &&  apt-get install -y apt-transport-https ca-certificates gnupg curl gcc g++
RUN apt-get install -y git
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
   &&  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
   &&  apt-get update -y \
   &&  apt-get install google-cloud-cli -y
RUN apt-get install -y jq screen ca-certificates
RUN mkdir -p /root
WORKDIR /root
COPY file:29571ccee8ed9a1e28dfebdedcb369249e3eaa83cd69c890b8dfe63172a6f6ec in README.md
COPY file:a4afcad055d85d3716d9eafc60f2b1b64173610895aac456506802c16afe69b2 in pyproject.toml
RUN mkdir axlearn \
   &&  touch axlearn/__init__.py
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH=/opt/venv/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN pip install flit
RUN pip install --upgrade pip
ENV RUN_PYTHON_SDK_IN_DEFAULT_ENVIRONMENT=1
RUN pip install .[gcp,dataflow,dev]
RUN pip install tensorflow==2.12
COPY dir:16aae2165bf4afa005a5637e8d6d50ab8d246e6427f25946840af3844788229e in .
COPY dir:2c0bc3f4fea8d3a8197fae57cc0c90e9d8bd95fd8299e09fbc264ec3a3afd19a in /opt/apache/beam
ENTRYPOINT ["/opt/apache/beam/boot"]