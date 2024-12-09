'''

Following this guide, deploy mixtral 8x7b via jetstream on GKE with TPUs

https://cloud.google.com/kubernetes-engine/docs/tutorials/serve-llm-tpu-jetstream-pytorch

'''

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

#store hugginface credentials
kubectl create secret generic huggingface-secret \
    --from-literal=HUGGINGFACE_TOKEN=$HF_TOKEN

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
