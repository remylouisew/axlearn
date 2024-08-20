FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04
FROM $BASE

# Check that the chosen base image provides the expected version of Python interpreter.
ARG PY_VERSION=3.9
RUN [[ $PY_VERSION == `python -c 'import sys; print("%s.%s" % sys.version_info[0:2])'` ]] \
   || { echo "Could not find Python interpreter or Python version is different from ${PY_VERSION}"; exit 1; }

# Install Google Cloud CLI
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && apt-get install -y google-cloud-sdk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
    
   # Install git.
RUN apt-get update && apt-get install -y git
#setup
RUN mkdir -p /root
WORKDIR /root
# Introduce the minimum set of files for install.
COPY README.md README.md
COPY pyproject.toml pyproject.toml
RUN mkdir axlearn && touch axlearn/__init__.py
# Setup venv to suppress pip warnings.
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
# Install dependencies.
RUN pip install flit
RUN pip install nvidia-ml-py
RUN pip install --upgrade pip

###############
#dataflow
###############

ENV RUN_PYTHON_SDK_IN_DEFAULT_ENVIRONMENT=1
RUN pip install .[gcp,dataflow,dev]
COPY . .

# Copy the Apache Beam worker dependencies from the Beam Python 3.6 SDK image.
COPY --from=apache/beam_python3.9_sdk:2.52.0 /opt/apache/beam /opt/apache/beam

# Apache Beam worker expects pip at /usr/local/bin/pip by default.
# Some images have pip in a different location. If necessary, make a symlink.
# This line can be omitted in Beam 2.30.0 and later versions.
RUN [[ `which pip` == "/usr/local/bin/pip" ]] || ln -s `which pip` /usr/local/bin/pip

# Set the entrypoint to Apache Beam SDK worker launcher.
ENTRYPOINT [ "/opt/apache/beam/boot" ]
