#This code will install axlearn and its dependencies
#https://github.com/apple/axlearn/blob/main/docs/01-start.md

#Download conda and python 3.9

!curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge-pypy3-MacOSX-x86_64.sh
!bash Miniforge-pypy3-MacOSX-x86_64.sh

export PATH="/Users/remyw/miniforge-pypy3/bin:$PATH"

#install axlearn in conda virtual env
conda create -n axlearn python=3.9
conda activate axlearn

pip install axlearn

pip install 'axlearn[gcp]'


#copy config file
cp '/Users/remyw/Documents/Code Projects/axlearn/axlearn.default.config' .axlearn/.axlearn.config
#linux version
mkdir .axlearn
cp '/usr/local/google/home/remyw/Documents/Apple/axlearn.config' ~/.axlearn/.axlearn.config

axlearn gcp config activate


#copy basic project setup
cp '/Users/remyw/Documents/Code Projects/axlearn/pyproject.toml' .

cp '/Users/remyw/Documents/Code Projects/axlearn/Dockerfile' .


#test

# Authenticate to GCP.
#make sure to `gcloud config set project cool-machine-learning` first
axlearn gcp auth

# Run a dummy command on v4-8.
# Note: the "'...'" quotes are important.
axlearn gcp tpu start --name=maggiejz-001-0206 --tpu_type=v5p-64 -- python3 -c "'import jax; print(jax.devices())'"

conda develop /Users/remyw/.docker/bin/


ls -ld /Users/remyw/.docker/bin/com.docker.cli

/Applications/Docker.app/Contents/Docker --uninstall

"{\"message\":\"removing app files: unlinkat /Users/remyw/Library/Containers/com.docker.helper/.com.apple.containermanagerd.metadata.plist: operation not permitted\"}\n{\"message\":\"removing app files: unlinkat /Users/remyw/Library/Containers/com.docker.helper/.com.apple.containermanagerd.metadata.plist: operation not permitted\"}\n{\"message\":\"removing app files: unlinkat /Users/remyw/Library/Containers/com.docker.helper/.com.apple.containermanagerd.metadata.plist: operation not permitted\"}\n"