FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04

# Install python and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update
RUN apt-get install -y apt-transport-https ca-certificates gnupg curl gcc g++

# Install git.
RUN apt-get install -y git

# Install gcloud. https://cloud.google.com/sdk/docs/install
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update -y && apt-get install google-cloud-cli -y

# Install screen and other utils for launch script.
RUN apt-get install -y jq screen ca-certificates

# Setup.
RUN mkdir -p /root
WORKDIR /root
# Introduce the minimum set of files for install.
COPY README.md README.md
COPY pyproject.toml pyproject.toml
RUN mkdir axlearn && touch axlearn/__init__.py

# Install dependencies.
RUN pip install flit
RUN pip install --upgrade pip


###############
#dataflow
###############

ENV RUN_PYTHON_SDK_IN_DEFAULT_ENVIRONMENT=1
RUN pip install .[gcp,dataflow,dev]
COPY . .

# Copy the Apache Beam worker dependencies from the Beam Python 3.6 SDK image.
COPY --from=apache/beam_python3.9_sdk:2.52.0 /opt/apache/beam /opt/apache/beam


# Set the entrypoint to Apache Beam SDK worker launcher.
ENTRYPOINT [ "/opt/apache/beam/boot" ]