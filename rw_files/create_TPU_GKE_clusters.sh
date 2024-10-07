
# A list of commands to create single-host slice, multi-host slice, and muli sclies in GKE
# Make sure to set the project using glcoud before you run the commands and change the 
# resource names such as cluster, node pool, and kms key.
### Single Slice ######
# commands to create a gke cluster in central2-b
gcloud container clusters create eshen-axlearn-tpu-a \
    --zone us-central2-b \
    --node-locations us-central2-b \
    --disk-size 20GB \
    --scopes=https://www.googleapis.com/auth/cloud-platform
# single host sclie v4-podslice 2X2X1
gcloud container node-pools create axlearn-pool \
    --location=us-central2-b \
    --cluster=eshen-axlearn-tpu-a \
    --node-locations=us-central2-b \
    --machine-type=ct4p-hightpu-4t \
    --tpu-topology 2x2x1 \
    --spot \
    --num-nodes=1 \
    ## uncomment the following for CHD
    ## --disk-type="hyperdisk-balanced" \  
    ## --boot-disk-kms-key="projects/cool-machine-learning/locations/us-east5/keyRings/eshen-chd-3/cryptoKeys/eshen-chd-key-3" \   
    ## --enable-confidential-storage \
    --scopes=https://www.googleapis.com/auth/cloud-platform
# multi-host slice v4-podslice 2X2X4
gcloud container node-pools create axlearn-pool-multihost \
    --location=us-central2-b \
    --cluster=eshen-axlearn-tpu-a \
    --node-locations=us-central2-b \
    --machine-type=ct4p-hightpu-4t \
    --tpu-topology 2x2x4 \
    --spot \
    --num-nodes=4 \
    ## uncomment the following for CHD
    ## --disk-type="hyperdisk-balanced" \  
    ## --boot-disk-kms-key="projects/cool-machine-learning/locations/us-east5/keyRings/eshen-chd-3/cryptoKeys/eshen-chd-key-3" \   
    ## --enable-confidential-storage \
    --scopes=https://www.googleapis.com/auth/cloud-platform
### Multi Slice ######
# run the following command for N slices. Each slice is a node pool
gcloud container node-pools create axlearn-pool-multihost-1 \
    --location=us-east5 \
    --cluster=tpu-provisioner-e2e-us-east5 \
    --node-locations=us-east5-a \
    --machine-type=ct5p-hightpu-4t \
    --tpu-topology=2x2x4 \
    --spot \
    --num-nodes=0 \
    --enable-autoscaling \
    --max-nodes=4 \
    ## uncomment the following for CHD
    ## --disk-type="hyperdisk-balanced" \  
    ## --boot-disk-kms-key="projects/cool-machine-learning/locations/us-east5/keyRings/eshen-chd-3/cryptoKeys/eshen-chd-key-3" \   
    ## --enable-confidential-storage \
    --scopes=https://www.googleapis.com/auth/cloud-platform

## RW test

#using tutorial from:
git clone https://github.com/GoogleCloudPlatform/ai-on-gke.git

gcloud container node-pools create rw-pool \
    --location=us-east5 \
    --cluster=maggiejz-tpu-east5 \
    --node-locations=us-east5-a \
    --machine-type=ct5p-hightpu-4t \
    --tpu-topology 2x2x1 \
    --spot \
    --num-nodes=1 \
    --scopes=https://www.googleapis.com/auth/cloud-platform


#Note: num-nodes have to match how many VMs there are. For example, 2x2x1 is v4-8, and it's 1 VM, so you put num-nodes=1
#2x2x1, v4-8, num-nodes=1
#2x2x2, v4-16, num-nodes=2
#2x2x4, v4-32, num-nodes=4
#2x4x4, v5p-64, num-nodes=8


    #connect to cluster
    # I had to update the k8 authentication to gcloud-auth-plugin version per this blog: https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke?e=48754805
    gcloud container clusters get-credentials rw-pool --location=us-east5

    #build and push the docker image
    cd ai-on-gke/tutorials-and-examples/tpu-examples/training/diffusion/
    docker build -t gcr.io/cool-machine-learning/diffusion:latest .
    docker push gcr.io/cool-machine-learning/diffusion:latest

    #copy job yaml 'tpu_job_description'

    #submit job
    kubectl apply -f tpu_job_diffusion.yaml

    gcloud container node-pools create v4-pool \
    --location=us-central2 \
    --cluster=maggiejz-tpu-regional \
    --node-locations=us-central2-b \
    --machine-type=ct4p-hightpu-4t \
    --tpu-topology 2x2x1 \
    --spot \
    --num-nodes=1 \
    --scopes=https://www.googleapis.com/auth/cloud-platform


    #test by submitting print devices job

export BASTION_TIER=1
axlearn gcp gke start --instance_type=tpu-v4-8 --num_replicas=1 \
        --cluster=maggiejz-tpu-regional \
        --bundler_type=artifactregistry --bundler_spec=image=tpu \
        --bundler_spec=dockerfile=Dockerfile --bundler_spec=target=tpu \
<<<<<<< HEAD
<<<<<<< HEAD
        --bundler_spec=allow_dirty=True \
=======
>>>>>>> e80131d (commit)
=======
        --bundler_spec=allow_dirty=True \
>>>>>>> a0277c9 (works now)
        -- python3 -c "'import jax; print(jax.devices())'"

