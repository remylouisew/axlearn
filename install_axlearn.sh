#This code will install axlearn and its dependencies
#https://github.com/apple/axlearn/blob/main/docs/01-start.md

#Download conda and python 3.9

!curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge-pypy3-MacOSX-x86_64.sh
!bash Miniforge-pypy3-MacOSX-x86_64.sh

export PATH="/Users/remyw/miniforge-pypy3/bin:$PATH"


#OLD don't do install axlearn in conda virtual env
conda create -n axlearn python=3.9
conda activate axlearn
pip install axlearn
pip install 'axlearn[gcp]'
###

#Create conda venv
conda create env --name rwaxlearn python=3.9
conda activate rwaxlearn

# Clone your fork of the repo.
git clone https://github.com/remylouisew/axlearn
cd axlearn

#make sure you have the full pyproject.toml with all the dependencies it in before next step (just rerun it if not)

#install packages in editable mode
pip install -e '.[core,dev]'
pip install -e '.[gcp]'


#copy config file
cp '/Users/remyw/Documents/Code Projects/axlearn/axlearn.default.config' .axlearn/.axlearn.config
#linux version
mkdir .axlearn
cp '/usr/local/google/home/remyw/Documents/Apple/axlearn.config' ~/.axlearn/.axlearn.config

axlearn gcp config activate


#copy basic project setup
cp '/Users/remyw/Documents/Code Projects/axlearn/pyproject.toml' .

cp '/Users/remyw/Documents/Code Projects/axlearn/Dockerfile' .


# Authenticate to GCP.
#make sure to `gcloud config set project cool-machine-learning` first
axlearn gcp auth

# Run a dummy command on v4-8.
# Note: the "'...'" quotes are important.
axlearn gcp tpu start --name=remyw-v5p --tpu_type=v5p-8 -- python3 -c "'import jax; print(jax.devices())'"
axlearn gcp tpu start --name=test1 --tpu_type=v4-8 -- python3 -c "'import jax; print(jax.devices())'"


conda develop /Users/remyw/.docker/bin/


ls -ld /Users/remyw/.docker/bin/com.docker.cli

/Applications/Docker.app/Contents/Docker --uninstall

"{\"message\":\"removing app files: unlinkat /Users/remyw/Library/Containers/com.docker.helper/.com.apple.containermanagerd.metadata.plist: operation not permitted\"}\n{\"message\":\"removing app files: unlinkat /Users/remyw/Library/Containers/com.docker.helper/.com.apple.containermanagerd.metadata.plist: operation not permitted\"}\n{\"message\":\"removing app files: unlinkat /Users/remyw/Library/Containers/com.docker.helper/.com.apple.containermanagerd.metadata.plist: operation not permitted\"}\n"