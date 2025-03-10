'''

Following this guide, deploy mixtral 8x7b via vllm on GKE with TPUs

https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-vllm-tpu#deploy-vllm

now have a copy of this on mac remyw/vllm

'''

git filter-repo --invert-paths --path mixtral_on_gke_tpu.py

export HF_TOKEN=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


gcloud config set project cool-machine-learning
export PROJECT_ID=$(gcloud config get project)
export CLUSTER_NAME=remyw-mistraltpu
export BUCKET_NAME=rw-cool-test
export REGION=us-west4
export LOCATION=us-west4
export CLUSTER_VERSION=1.28.14-gke.1099000

#create cluster

#configure kubectl to communicate with your cluster
gcloud container clusters get-credentials $CLUSTER_NAME --location=$REGION

#store huggingface credentials
kubectl create secret generic hf-secret \
    --from-literal=hf_api_token=HUGGING_FACE_TOKEN \


#create service account
gcloud iam service-accounts create wi-jetstream

#setup IAM policy bilding to manage cloud storage...other steps here but not includng them because already done
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member "serviceAccount:wi-jetstream@PROJECT_ID.iam.gserviceaccount.com" \
    --role roles/storage.objectUser

gcloud projects add-iam-policy-binding PROJECT_ID \
    --member "serviceAccount:wi-jetstream@PROJECT_ID.iam.gserviceaccount.com" \
    --role roles/storage.insightsCollectorService


#jesus build image for yaml

git clone https://github.com/vllm-project/vllm && cd vllm
DOCKER_BUILDKIT=1 docker build -f Dockerfile.tpu . -t vllm-tpu
docker image tag vllm-tpu us-east1-docker.pkg.dev/cool-machine-learning/vllm-tpu/vllm-tpu:testrw && docker push us-east1-docker.pkg.dev/cool-machine-learning/vllm-tpu/vllm-tpu:testrw

#deploy the application

#first set to my cluster
gcloud container clusters get-credentials pii-oss-test-cluster-remyw --location=us-west1 --project=cool-machine-learning \
--dns-endpoint
--tunnel-through-iap
--internal-ip

gcloud container clusters get-credentials pii-oss-test-cluster-kevinaschmidt --location=us-west1 --project=cool-machine-learning



##kubectl debugging
kubectl config view

kubectl apply -f deployment.yaml

#look at the rescources you deployed
kubectl describe deployment vllm-tpu


#get list of authorized networks
gcloud container clusters describe pii-oss-test-cluster-remyw \
    --location=us-west1\
    --project=cool-machine-learning \
    --format "flattened(controlPlaneEndpointsConfig.ipEndpointsConfig.authorizedNetworksConfig.cidrBlocks[])"

#add cidr blocks to authorized networks
gcloud container clusters update pii-oss-test-cluster-remyw \
--location=us-west1 \
--enable-ip-access  \
--enable-master-authorized-networks \
--enable-master-global-access \
--master-authorized-networks=35.186.0.0/16,192.168.0.0/16,17.0.0.0/8,127.0.0.0/16


