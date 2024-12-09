#Test on standalone VM

#cos
#to deploy container, you need to authenticate, and to authenticate, you need gcloud, which cos doesnt have
#to install anything, you need to use toolbox
toolbox apt install google-cloud-sdk
#or to authenticate (this is what I did)
toolbox gcloud auth configure-docker us-central1-docker.pkg.dev
#have to move auth credentials into folder where docker can see them
toolbox gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin us-central1-docker.pkg.dev

#use GPU-enabled image
docker-credential-gcr configure-docker
docker run --rm \
  -it \
  --entrypoint=/bin/bash \
  --volume /var/lib/nvidia/lib64:/usr/local/nvidia/lib64 \
  --volume /var/lib/nvidia/bin:/usr/local/nvidia/bin \
  --privileged \
  us-central1-docker.pkg.dev/cool-machine-learning/rw-dataflow/py10v2


#inference on CPU, test on VM

#launch container on vm
docker-credential-gcr configure-docker
docker run --rm \
  -it \
  --entrypoint=/bin/bash \
  --volume /var/lib/nvidia/lib64:/usr/local/nvidia/lib64 \
  --volume /var/lib/nvidia/bin:/usr/local/nvidia/bin \
  --privileged \
  us-central1-docker.pkg.dev/cool-machine-learning/rw-dataflow/py10v2

#install additional packages needed for this inference example
pip install .[core]

# location to emit training artifacts like checkpoints and summaries
OUTPUT_DIR=gs://ttl-30d-us-central2/axlearn/users/maggiejz/maggiejz-002-01

# public dataset provided by AXLearn team
DATA_DIR=gs://axlearn-public/tensorflow_datasets 


python3 -m axlearn.cloud.gcp.examples.dataflow_inference_custom \
--module=text.gpt.c4_trainer \
        --config=fuji-7B-v1-flash-single-host \
        --trainer_dir=gs://ttl-30d-us-central2/axlearn/users/maggiejz/maggiejz-002-01tmp/test_trainer \
        --data_dir=gs://axlearn-public/tensorflow_datasets \
   --runner=DirectRunner \
   --project=cool-machine-learning \
   --worker_machine_type=n1-highmem-16 \
   --disk_size_gb=200 \
    --region=us-west1 --temp_location=gs://dataflow-test-bucket0/rwtest/temp/ \
     --staging_location=gs://dataflow-test-bucket0/rwtest/staging \
      --service_account_email=ml-training@cool-machine-learning.iam.gserviceaccount.com




  # inference with CPU





    axlearn gcp dataflow start \
    --bundler_spec=dockerfile=Dockerfile.py10v2 \
    --bundler_spec=repo=${DOCKER_REPO} \
    --bundler_spec=allow_dirty=True \
    --dataflow_spec=runner=DataflowRunner \
    --dataflow_spec=disk_size_gb=200 \
    --dataflow_spec=region=us-west1 \
    --dataflow_spec=worker_machine_type=n1-standard-16 \
    -- python3 -m axlearn.cloud.gcp.examples.dataflow_inference_hf 