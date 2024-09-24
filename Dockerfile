#dockerfile with downgraded versions

#ARG TARGET=base
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04 

# Install python and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3.8-venv && \
    rm -rf /var/lib/apt/lists/* 
 
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg curl gcc g++

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
#COPY axlearn/axlearn/cloud/gcp/examples/ .
#RUN ls -la /axlearn/axlearn/cloud/gcp/examples/*
RUN mkdir axlearn && touch axlearn/__init__.py
# Setup venv to suppress pip warnings.
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
# Install dependencies.
RUN pip install flit
RUN pip install --upgrade pip


###############
#dataflow
###############
#FROM base AS dataflow


ENV RUN_PYTHON_SDK_IN_DEFAULT_ENVIRONMENT=1
#gpu packages are my own specified list (see pyproject.toml)
RUN pip install .[gcp,dataflow,dev] 
RUN pip install tensorflow==2.12
COPY . .

#COPY . /pipeline
##COPY requirements.txt .
#COPY *.py ./

# Copy the Apache Beam worker dependencies from the Beam Python 3.10 SDK image.
COPY --from=apache/beam_python3.8_sdk:2.52.0 /opt/apache/beam /opt/apache/beam
# Set the entrypoint to Apache Beam SDK worker launcher.
ENTRYPOINT [ "/opt/apache/beam/boot" ]